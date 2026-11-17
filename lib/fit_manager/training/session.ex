defmodule FitManager.Training.Session do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sessions" do
    field :scheduled_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :duration_minutes, :integer, default: 60
    field :duration_min, :integer, default: 60
    field :status, :string, default: "scheduled"
    field :notes, :string

    belongs_to :client, FitManager.Clients.Client
    belongs_to :training_plan, FitManager.Training.TrainingPlan
    belongs_to :plan, FitManager.Training.TrainingPlan, foreign_key: :plan_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [
      :client_id,
      :training_plan_id,
      :plan_id,
      :scheduled_at,
      :completed_at,
      :duration_minutes,
      :duration_min,
      :status,
      :notes
    ])
    |> normalize_fields()
    |> validate_required([:client_id, :scheduled_at])
    |> validate_inclusion(:status, ["scheduled", "completed", "cancelled", "no_show"])
    |> validate_number(:duration_minutes, greater_than: 0)
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:training_plan_id)
    |> foreign_key_constraint(:plan_id)
  end

  defp normalize_fields(changeset) do
    training_plan_id = get_change(changeset, :training_plan_id) || get_field(changeset, :training_plan_id)
    plan_id = get_change(changeset, :plan_id) || get_field(changeset, :plan_id)

    changeset =
      cond do
        training_plan_id && is_nil(plan_id) ->
          put_change(changeset, :plan_id, training_plan_id)

        plan_id && is_nil(training_plan_id) ->
          put_change(changeset, :training_plan_id, plan_id)

        true ->
          changeset
      end

    duration_minutes = get_change(changeset, :duration_minutes) || get_field(changeset, :duration_minutes)
    duration_min = get_change(changeset, :duration_min) || get_field(changeset, :duration_min)

    cond do
      duration_minutes && is_nil(duration_min) ->
        put_change(changeset, :duration_min, duration_minutes)

      duration_min && is_nil(duration_minutes) ->
        put_change(changeset, :duration_minutes, duration_min)

      true ->
        changeset
    end
  end
end
