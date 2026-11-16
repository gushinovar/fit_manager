terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 1. Enable required APIs
resource "google_project_service" "compute_api" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# 2. VPC Firewall rule for HTTP, HTTPS, and Phoenix API port (4000)
resource "google_compute_firewall" "fit_manager_firewall" {
  name    = "fit-manager-allow-web"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "4000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["fit-manager-node"]

  depends_on = [google_project_service.compute_api]
}

# 3. Always-Free Tier Compute Engine Instance (e2-micro in us-central1)
resource "google_compute_instance" "fit_manager_vm" {
  name         = "fit-manager-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["fit-manager-node"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30 # 30 GB standard disk is included in Always Free
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP to connect from outside
    }
  }

  # Startup script to configure Linux, Swap, PostgreSQL, and Elixir/Phoenix
  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e

    # Create 2GB swap file to support 1GB RAM effortlessly
    if [ ! -f /swapfile ]; then
      fallocate -l 2G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    # System updates and packages
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y git curl ufw postgresql postgresql-contrib elixir erlang-base

    # Setup PostgreSQL user and databases
    systemctl enable postgresql
    systemctl start postgresql
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
    sudo -u postgres psql -c "CREATE DATABASE fit_manager_dev OWNER postgres;" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE DATABASE fit_manager_test OWNER postgres;" 2>/dev/null || true

    # Prepare project directory
    mkdir -p /opt/fit_manager
    cd /opt
    if [ ! -d "/opt/fit_manager/.git" ]; then
      git clone https://github.com/gushinovar/fit_manager.git /opt/fit_manager
    fi

    cd /opt/fit_manager
    mix local.hex --force
    mix local.rebar --force
    mix deps.get
    mix ecto.create || true

    # Create systemd service for 24/7 background uptime
    cat << 'SERVICE' > /etc/systemd/system/fit_manager.service
    [Unit]
    Description=FitManager Phoenix API Service
    After=network.target postgresql.service

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/opt/fit_manager
    Environment=MIX_ENV=dev
    Environment=PORT=4000
    ExecStart=/usr/bin/mix phx.server
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable fit_manager
    systemctl restart fit_manager
  EOT

  depends_on = [google_project_service.compute_api, google_compute_firewall.fit_manager_firewall]
}
