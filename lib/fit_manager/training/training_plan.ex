defmodule FitManager.Training.TrainingPlan do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "training_plans" do
    field :name, :string
    field :description, :string
    field :goal, :string
    field :days_per_week, :integer
    field :exercises, :map, default: %{}
    field :plan_details, :map, default: %{}
    field :active, :boolean, default: true
    field :status, :string, default: "active"
    field :start_date, :date
    field :end_date, :date

    belongs_to :client, FitManager.Clients.Client
    has_many :sessions, FitManager.Training.Session

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(training_plan, attrs) do
    training_plan
    |> cast(attrs, [
      :client_id,
      :name,
      :description,
      :goal,
      :days_per_week,
      :exercises,
      :plan_details,
      :active,
      :status,
      :start_date,
      :end_date
    ])
    |> normalize_fields()
    |> validate_required([:client_id, :name])
    |> validate_inclusion(:status, ["active", "completed", "paused"])
    |> validate_number(:days_per_week, greater_than: 0, less_than_or_equal_to: 7)
    |> foreign_key_constraint(:client_id)
  end

  defp normalize_fields(changeset) do
    exercises = get_change(changeset, :exercises) || get_field(changeset, :exercises)
    plan_details = get_change(changeset, :plan_details) || get_field(changeset, :plan_details)

    changeset =
      cond do
        exercises != %{} and plan_details == %{} ->
          put_change(changeset, :plan_details, exercises)

        plan_details != %{} and exercises == %{} ->
          put_change(changeset, :exercises, plan_details)

        true ->
          changeset
      end

    goal = get_change(changeset, :goal) || get_field(changeset, :goal)
    description = get_change(changeset, :description) || get_field(changeset, :description)

    cond do
      goal && is_nil(description) ->
        put_change(changeset, :description, goal)

      description && is_nil(goal) ->
        put_change(changeset, :goal, description)

      true ->
        changeset
    end
  end
end
