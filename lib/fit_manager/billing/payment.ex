defmodule FitManager.Billing.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "payments" do
    field :amount, :decimal
    field :currency, :string, default: "EUR"
    field :status, :string, default: "pending"
    field :concept, :string
    field :payment_method, :string
    field :period_month, :string
    field :payment_date, :date
    field :due_date, :date
    field :paid_at, :utc_datetime
    field :notes, :string

    belongs_to :client, FitManager.Clients.Client

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [
      :client_id,
      :amount,
      :currency,
      :status,
      :concept,
      :payment_method,
      :period_month,
      :payment_date,
      :due_date,
      :paid_at,
      :notes
    ])
    |> validate_required([:client_id, :amount])
    |> validate_inclusion(:status, ["pending", "paid", "overdue", "cancelled"])
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:client_id)
  end
end
