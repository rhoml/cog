defmodule Cog.V1.ChatHandleController do
  use Cog.Web, :controller

  alias Cog.Models.EctoJson
  alias Cog.Models.ChatHandle
  alias Cog.Models.ChatProvider

  plug Cog.Plug.Authentication
  plug Cog.Plug.Authorization, permission: "#{Cog.embedded_bundle}:manage_users"

  plug :scrub_params, "chat_handle" when action in [:create, :update]

  def index(conn, %{"id" => user_id}) do
    chat_handles = Cog.Queries.User.handles(user_id)
    |> Repo.all
    |> Repo.preload([:chat_provider, :user])
    json(conn, EctoJson.render(chat_handles, envelope: :chat_handles))
  end
  def index(conn, _params) do
    chat_handles = Repo.all(ChatHandle)
    |> Repo.preload([:chat_provider, :user])
    json(conn, EctoJson.render(chat_handles, envelope: :chat_handles))
  end

  def create(conn, %{"chat_handle" => chat_handle_params, "id" => user_id}) do
    params = get_changeset_params(chat_handle_params, user_id)
    changeset = ChatHandle.changeset(%ChatHandle{}, params)

    case Repo.insert(changeset) do
      {:ok, chat_handle} ->
        chat_handle = Repo.preload(chat_handle, [:chat_provider, :user])
        conn
        |> put_status(:created)
        |> json(EctoJson.render(chat_handle, envelope: :chat_handle, policy: :detail))
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Cog.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    Repo.get!(ChatHandle, id)
    |> Repo.delete!
    send_resp(conn, :no_content, "")
  end

  def update(conn, %{"id" => id, "chat_handle" => chat_handle_params}) do
    chat_handle = Repo.get!(ChatHandle, id)
    params = get_changeset_params(chat_handle_params, chat_handle.user_id)
    changeset = ChatHandle.changeset(chat_handle, params)

    case Repo.update(changeset) do
      {:ok, chat_handle} ->
        chat_handle = Repo.preload(chat_handle, [:chat_provider, :user])
        json(conn, EctoJson.render(chat_handle, envelope: :chat_handle, policy: :detail))
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Cog.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp get_changeset_params(%{"chat_provider" => provider_name, "handle" => handle}, user_id) do
    provider = Repo.get_by(ChatProvider, name: provider_name)
    %{"handle" => handle,
      "provider_id" => provider.id,
      "user_id" => user_id}
  end
end