defmodule FitManagerWeb.Router do
  use FitManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", FitManagerWeb do
    pipe_through :api
    # Rutas se agregarán en siguientes tareas
  end
end
