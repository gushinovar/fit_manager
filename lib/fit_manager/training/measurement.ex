defmodule FitManager.Training.Measurement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "measurements" do
    field :measured_at, :date
    field :date, :date
    field :weight_kg, :decimal
    field :height_cm, :decimal
    field :body_fat_pct, :decimal
    field :body_fat_percentage, :decimal
    field :muscle_mass_kg, :decimal
    field :waist_cm, :decimal
    field :chest_cm, :decimal
    field :arm_cm, :decimal
    field :leg_cm, :decimal
    field :hips_cm, :decimal
    field :circumferences, :map, default: %{}
    field :notes, :string

    belongs_to :client, FitManager.Clients.Client

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(measurement, attrs) do
    measurement
    |> cast(attrs, [
      :client_id,
      :measured_at,
      :date,
      :weight_kg,
      :height_cm,
      :body_fat_pct,
      :body_fat_percentage,
      :muscle_mass_kg,
      :waist_cm,
      :chest_cm,
      :arm_cm,
      :leg_cm,
      :hips_cm,
      :circumferences,
      :notes
    ])
    |> normalize_fields()
    |> validate_required([:client_id])
    |> validate_number(:weight_kg, greater_than: 0)
    |> foreign_key_constraint(:client_id)
  end

  defp normalize_fields(changeset) do
    measured_at = get_change(changeset, :measured_at) || get_field(changeset, :measured_at)
    date = get_change(changeset, :date) || get_field(changeset, :date)

    changeset =
      cond do
        measured_at && is_nil(date) ->
          put_change(changeset, :date, measured_at)

        date && is_nil(measured_at) ->
          put_change(changeset, :measured_at, date)

        is_nil(measured_at) && is_nil(date) ->
          today = Date.utc_today()

          changeset
          |> put_change(:measured_at, today)
          |> put_change(:date, today)

        true ->
          changeset
      end

    body_fat_pct = get_change(changeset, :body_fat_pct) || get_field(changeset, :body_fat_pct)
    body_fat_percentage = get_change(changeset, :body_fat_percentage) || get_field(changeset, :body_fat_percentage)

    cond do
      body_fat_pct && is_nil(body_fat_percentage) ->
        put_change(changeset, :body_fat_percentage, body_fat_pct)

      body_fat_percentage && is_nil(body_fat_pct) ->
        put_change(changeset, :body_fat_pct, body_fat_percentage)

      true ->
        changeset
    end
  end
end
