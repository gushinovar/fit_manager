defmodule FitManager.Repo do
  use Ecto.Repo,
    otp_app: :fit_manager,
    adapter: Ecto.Adapters.Postgres
end
