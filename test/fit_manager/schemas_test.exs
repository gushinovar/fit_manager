defmodule FitManager.SchemasTest do
  use FitManager.DataCase, async: true

  alias FitManager.Clients.Client
  alias FitManager.Training.TrainingPlan
  alias FitManager.Training.Session
  alias FitManager.Training.Measurement
  alias FitManager.Billing.Payment
  alias FitManager.Messaging.Conversation

  describe "clients schema and changeset" do
    @valid_client_attrs %{
      first_name: "John",
      last_name: "Doe",
      phone: "+34612345678",
      email: "john@example.com",
      status: "active",
      gender: "male",
      goals: "Hypertrophy",
      medical_notes: "None"
    }

    test "valid with required attributes" do
      changeset = Client.changeset(%Client{}, @valid_client_attrs)
      assert changeset.valid?
      assert get_field(changeset, :name) == "John Doe"
    end

    test "supports passing unified name attribute" do
      changeset = Client.changeset(%Client{}, %{name: "Jane Smith", phone: "+34612345679"})
      assert changeset.valid?
      assert get_field(changeset, :first_name) == "Jane"
      assert get_field(changeset, :last_name) == "Smith"
    end

    test "invalid without phone" do
      changeset = Client.changeset(%Client{}, %{@valid_client_attrs | phone: nil})
      refute changeset.valid?
      assert %{phone: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid phone format" do
      changeset = Client.changeset(%Client{}, %{@valid_client_attrs | phone: "12345"})
      refute changeset.valid?
      assert %{phone: ["must be in E.164 format (e.g. +34612345678)"]} = errors_on(changeset)
    end

    test "invalid status" do
      changeset = Client.changeset(%Client{}, %{@valid_client_attrs | status: "unknown"})
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "inserts into database successfully" do
      {:ok, client} = Repo.insert(Client.changeset(%Client{}, @valid_client_attrs))
      assert client.id != nil
      assert client.phone == "+34612345678"
    end
  end

  describe "training_plans schema and changeset" do
    setup do
      {:ok, client} =
        Repo.insert(
          Client.changeset(%Client{}, %{
            first_name: "Alice",
            last_name: "Wonder",
            phone: "+34611111111"
          })
        )

      %{client: client}
    end

    test "valid with required attributes", %{client: client} do
      attrs = %{
        client_id: client.id,
        name: "Strength Block 1",
        days_per_week: 4,
        goal: "Strength",
        status: "active"
      }

      changeset = TrainingPlan.changeset(%TrainingPlan{}, attrs)
      assert changeset.valid?

      {:ok, plan} = Repo.insert(changeset)
      assert plan.client_id == client.id
      assert plan.description == "Strength"
    end

    test "invalid without client_id or name" do
      changeset = TrainingPlan.changeset(%TrainingPlan{}, %{})
      refute changeset.valid?
      assert %{client_id: ["can't be blank"], name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "sessions schema and changeset" do
    setup do
      {:ok, client} =
        Repo.insert(
          Client.changeset(%Client{}, %{
            first_name: "Bob",
            last_name: "Builder",
            phone: "+34622222222"
          })
        )

      {:ok, plan} =
        Repo.insert(
          TrainingPlan.changeset(%TrainingPlan{}, %{
            client_id: client.id,
            name: "Hypertrophy"
          })
        )

      %{client: client, plan: plan}
    end

    test "valid session creation", %{client: client, plan: plan} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        client_id: client.id,
        training_plan_id: plan.id,
        scheduled_at: now,
        duration_minutes: 60,
        status: "scheduled"
      }

      changeset = Session.changeset(%Session{}, attrs)
      assert changeset.valid?

      {:ok, session} = Repo.insert(changeset)
      assert session.client_id == client.id
      assert session.training_plan_id == plan.id
      assert session.duration_min == 60
    end

    test "invalid session status" do
      changeset = Session.changeset(%Session{}, %{status: "invalid"})
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "measurements schema and changeset" do
    setup do
      {:ok, client} =
        Repo.insert(
          Client.changeset(%Client{}, %{
            first_name: "Charlie",
            last_name: "Brown",
            phone: "+34633333333"
          })
        )

      %{client: client}
    end

    test "valid measurement creation", %{client: client} do
      attrs = %{
        client_id: client.id,
        weight_kg: Decimal.new("75.50"),
        body_fat_pct: Decimal.new("15.20"),
        muscle_mass_kg: Decimal.new("35.00"),
        waist_cm: Decimal.new("80.00"),
        chest_cm: Decimal.new("98.00")
      }

      changeset = Measurement.changeset(%Measurement{}, attrs)
      assert changeset.valid?

      {:ok, measurement} = Repo.insert(changeset)
      assert measurement.client_id == client.id
      assert measurement.measured_at != nil
      assert measurement.date == measurement.measured_at
    end
  end

  describe "payments schema and changeset" do
    setup do
      {:ok, client} =
        Repo.insert(
          Client.changeset(%Client{}, %{
            first_name: "Diana",
            last_name: "Prince",
            phone: "+34644444444"
          })
        )

      %{client: client}
    end

    test "valid payment creation", %{client: client} do
      attrs = %{
        client_id: client.id,
        amount: Decimal.new("50.00"),
        currency: "EUR",
        status: "paid",
        concept: "Monthly Fee",
        payment_method: "transfer"
      }

      changeset = Payment.changeset(%Payment{}, attrs)
      assert changeset.valid?

      {:ok, payment} = Repo.insert(changeset)
      assert payment.client_id == client.id
      assert payment.amount == Decimal.new("50.00")
    end

    test "invalid payment amount <= 0", %{client: client} do
      attrs = %{
        client_id: client.id,
        amount: Decimal.new("0.00")
      }

      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert %{amount: ["must be greater than 0"]} = errors_on(changeset)
    end
  end

  describe "conversations schema and changeset" do
    setup do
      {:ok, client} =
        Repo.insert(
          Client.changeset(%Client{}, %{
            first_name: "Evan",
            last_name: "Stone",
            phone: "+34655555555"
          })
        )

      %{client: client}
    end

    test "valid conversation with client", %{client: client} do
      attrs = %{
        client_id: client.id,
        phone: client.phone,
        channel: "whatsapp",
        direction: "inbound",
        message: "Hello coach!"
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      assert changeset.valid?

      {:ok, conv} = Repo.insert(changeset)
      assert conv.client_id == client.id
      assert conv.message_body == "Hello coach!"
      assert conv.message_at != nil
    end

    test "valid conversation without client (prospect inquiry)" do
      attrs = %{
        phone: "+34699999999",
        channel: "whatsapp",
        direction: "inbound",
        message_body: "Hi, I want information about training"
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      assert changeset.valid?

      {:ok, conv} = Repo.insert(changeset)
      assert conv.client_id == nil
      assert conv.message == "Hi, I want information about training"
    end

    test "invalid without message or direction" do
      changeset = Conversation.changeset(%Conversation{}, %{phone: "+34600000000"})
      refute changeset.valid?
      assert %{direction: ["can't be blank"], message: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
