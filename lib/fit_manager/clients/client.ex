defmodule FitManager.Clients.Client do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "clients" do
    field :first_name, :string
    field :last_name, :string
    field :name, :string
    field :phone, :string
    field :email, :string
    field :birth_date, :date
    field :gender, :string
    field :goals, :string
    field :medical_notes, :string
    field :status, :string, default: "prospect"
    field :plan_type, :string
    field :monthly_fee, :decimal
    field :notes, :string

    has_many :training_plans, FitManager.Training.TrainingPlan
    has_many :plans, FitManager.Training.TrainingPlan
    has_many :sessions, FitManager.Training.Session
    has_many :measurements, FitManager.Training.Measurement
    has_many :payments, FitManager.Billing.Payment
    has_many :conversations, FitManager.Messaging.Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [
      :first_name,
      :last_name,
      :name,
      :phone,
      :email,
      :birth_date,
      :gender,
      :goals,
      :medical_notes,
      :status,
      :plan_type,
      :monthly_fee,
      :notes
    ])
    |> normalize_names()
    |> validate_required([:first_name, :last_name, :phone])
    |> validate_inclusion(:status, ["active", "inactive", "prospect"])
    |> validate_inclusion(:gender, ["male", "female", "other"])
    |> validate_format(:phone, ~r/^\+[1-9]\d{1,14}$/, message: "must be in E.164 format (e.g. +34612345678)")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:phone)
  end

  defp normalize_names(changeset) do
    first = get_change(changeset, :first_name) || get_field(changeset, :first_name)
    last = get_change(changeset, :last_name) || get_field(changeset, :last_name)
    name = get_change(changeset, :name) || get_field(changeset, :name)

    cond do
      first && last && is_nil(name) ->
        put_change(changeset, :name, "#{first} #{last}")

      name && (is_nil(first) || is_nil(last)) ->
        parts = String.split(name, ~r/\s+/, parts: 2)
        f = List.first(parts) || ""
        l = Enum.at(parts, 1) || ""

        changeset
        |> put_change(:first_name, first || f)
        |> put_change(:last_name, last || l)

      true ->
        changeset
    end
  end
end
