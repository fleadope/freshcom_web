defmodule FreshcomWeb.AccountController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller

  alias Freshcom.Identity

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # CreateAccount
  def create(conn, %{"data" => %{"type" => "Account"}}) do
    conn
    |> build_request(:create)
    |> Identity.create_account()
    |> send_response(conn, :create)
  end

  # RetrieveCurrentAccount
  def show(conn, _) do
    conn
    |> build_request(:show)
    |> Identity.get_account()
    |> send_response(conn, :show)
  end

  # UpdateCurrentAccount
  def update(conn, _) do
    conn
    |> build_request(:update)
    |> Identity.update_account_info()
    |> send_response(conn, :show)
  end
end
