defmodule FreshcomWeb.UserController do
  use FreshcomWeb, :controller
  import FreshcomWeb.Controller
  import FreshcomWeb.Normalization, only: [underscore: 1]

  alias Freshcom.{Identity, Response}

  action_fallback FreshcomWeb.FallbackController

  plug :scrub_params, "data" when action in [:create, :update]

  # ListUser
  def index(conn, _) do
    req =
      conn
      |> build_request(:index)
      |> normalize_request(:filter, "role", &underscore/1)

    case Identity.list_user(req) do
      {:ok, resp} ->
        {:ok, %{data: total_count}} = Identity.count_user(req)
        {:ok, %{data: all_count}} = Identity.count_user(%{req | filter: [], search: nil})

        resp
        |> Response.put_meta(:total_count, total_count)
        |> Response.put_meta(:all_count, all_count)
        |> send_response(conn, :index)

      other ->
        send_response(other, conn, :index)
    end
  end

  # RegisterUser
  def create(%{assigns: %{account_id: nil}} = conn, %{"data" => %{"type" => "User"}}) do
    conn
    |> build_request(:create)
    |> Identity.register_user()
    |> send_response(conn, :create)
  end

  # AddUser
  def create(conn, %{"data" => %{"type" => "User"}}) do
    conn
    |> build_request(:create)
    |> normalize_request(:fields, "role", &underscore/1)
    |> Identity.add_user()
    |> send_response(conn, :create)
  end

  # RetrieveUser
  def show(conn, %{"id" => _}) do
    conn
    |> build_request(:show)
    |> Identity.get_user()
    |> send_response(conn, :show)
  end

  # RetrieveCurrentUser
  def show(%{assigns: assigns} = conn, _) do
    conn
    |> build_request(:show)
    |> Request.put(:identifiers, "id", assigns[:requester_id])
    |> Identity.get_user()
    |> send_response(conn, :show)
  end

  # UpdateUser
  def update(conn, _) do
    conn
    |> build_request(:update)
    |> Identity.update_user_info()
    |> send_response(conn, :show)
  end

  # ChangeUserRole
  def change_role(conn, _) do
    conn
    |> build_request(:update)
    |> normalize_request(:fields, "value", &underscore/1)
    |> Identity.change_user_role()
    |> send_response(conn, :show)
  end

  # GeneratePasswordResetToken
  def generate_password_reset_token(%{assigns: assigns} = conn, _) do
    response =
      conn
      |> build_request(:update, identifiers: ["id", "username"])
      |> Identity.generate_password_reset_token()

    if assigns[:requester_id] do
      send_response(response, conn, :create)
    else
      send_response(response, conn, :show, status: :no_content)
    end
  end

  # ChangePassword
  def change_password(conn, _) do
    conn
    |> build_request(:update, identifiers: ["id", "reset_token"])
    |> Identity.change_password()
    |> send_response(conn, :show)
  end

  # DeleteUser
  def delete(conn, _) do
    conn
    |> build_request(:delete, identifiers: ["id"])
    |> Identity.delete_user()
    |> send_response(conn, :delete, status: :no_content)
  end
end
