defmodule FitManager.Training.Plan do
  @moduledoc """
  Alias/wrapper module for `FitManager.Training.TrainingPlan`.
  """
  defdelegate changeset(plan, attrs), to: FitManager.Training.TrainingPlan
  defdelegate __struct__(), to: FitManager.Training.TrainingPlan
  defdelegate __struct__(kv), to: FitManager.Training.TrainingPlan
  defdelegate __schema__(action), to: FitManager.Training.TrainingPlan
  defdelegate __schema__(action, args), to: FitManager.Training.TrainingPlan
end
