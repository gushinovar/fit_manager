defmodule FitManager.Repo.Migrations.CreateAllTables do
  use Ecto.Migration

  def change do
    # 1. Clients
    create table(:clients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :first_name, :string
      add :last_name, :string
      add :name, :string
      add :phone, :string, null: false
      add :email, :string
      add :birth_date, :date
      add :gender, :string
      add :goals, :text
      add :medical_notes, :text
      add :status, :string, default: "prospect", null: false
      add :plan_type, :string
      add :monthly_fee, :decimal, precision: 10, scale: 2
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:clients, [:phone])
    create index(:clients, [:status])

    # 2. Training Plans
    create table(:training_plans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :goal, :string
      add :days_per_week, :integer
      add :exercises, :map
      add :plan_details, :map
      add :active, :boolean, default: true, null: false
      add :status, :string, default: "active", null: false
      add :start_date, :date
      add :end_date, :date

      timestamps(type: :utc_datetime)
    end

    create index(:training_plans, [:client_id])
    create index(:training_plans, [:status])

    # 3. Sessions
    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false
      add :training_plan_id, references(:training_plans, type: :binary_id, on_delete: :nilify_all)
      add :plan_id, references(:training_plans, type: :binary_id, on_delete: :nilify_all)
      add :scheduled_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :duration_minutes, :integer, default: 60
      add :duration_min, :integer, default: 60
      add :status, :string, default: "scheduled", null: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:sessions, [:client_id])
    create index(:sessions, [:training_plan_id])
    create index(:sessions, [:plan_id])
    create index(:sessions, [:scheduled_at])
    create index(:sessions, [:status])

    # 4. Measurements
    create table(:measurements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false
      add :measured_at, :date
      add :date, :date
      add :weight_kg, :decimal, precision: 6, scale: 2
      add :height_cm, :decimal, precision: 6, scale: 2
      add :body_fat_pct, :decimal, precision: 5, scale: 2
      add :body_fat_percentage, :decimal, precision: 5, scale: 2
      add :muscle_mass_kg, :decimal, precision: 6, scale: 2
      add :waist_cm, :decimal, precision: 6, scale: 2
      add :chest_cm, :decimal, precision: 6, scale: 2
      add :arm_cm, :decimal, precision: 6, scale: 2
      add :leg_cm, :decimal, precision: 6, scale: 2
      add :hips_cm, :decimal, precision: 6, scale: 2
      add :circumferences, :map
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:measurements, [:client_id])
    create index(:measurements, [:measured_at])
    create index(:measurements, [:date])

    # 5. Payments
    create table(:payments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :currency, :string, default: "EUR", null: false
      add :status, :string, default: "pending", null: false
      add :concept, :string
      add :payment_method, :string
      add :period_month, :string
      add :payment_date, :date
      add :due_date, :date
      add :paid_at, :utc_datetime
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:payments, [:client_id])
    create index(:payments, [:status])
    create index(:payments, [:due_date])

    # 6. Conversations
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, references(:clients, type: :binary_id, on_delete: :nilify_all)
      add :phone, :string
      add :channel, :string, default: "whatsapp", null: false
      add :direction, :string, null: false
      add :message, :text
      add :message_body, :text
      add :status, :string, default: "received"
      add :message_at, :utc_datetime
      add :meta_message_id, :string
      add :metadata, :map
      add :raw_payload, :map

      timestamps(type: :utc_datetime)
    end

    create index(:conversations, [:client_id])
    create index(:conversations, [:phone])
    create index(:conversations, [:message_at])
  end
end
