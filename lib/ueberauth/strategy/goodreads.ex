defmodule Ueberauth.Strategy.Goodreads do
  @moduledoc """
  Goodreads Strategy for Überauth.
  """

  use Ueberauth.Strategy, uid_field: :id_str

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Goodreads

  @doc """
  Handles initial request for Goodreads authentication.
  """
  def handle_request!(conn) do
    token = Goodreads.OAuth.request_token!([], [redirect_uri: callback_url(conn)])

    conn
    |> put_session(:goodreads_token, token)
    |> redirect!(Goodreads.OAuth.authorize_url!(token))
  end

  @doc """
  Handles the callback from Goodreads.
  """
  def handle_callback!(%Plug.Conn{params: %{"oauth_verifier" => oauth_verifier}} = conn) do
    token = get_session(conn, :goodreads_token)
    case Goodreads.OAuth.access_token(token, oauth_verifier) do
      {:ok, access_token} -> fetch_user(conn, access_token)
      {:error, error} -> set_errors!(conn, [error(error.code, error.reason)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:goodreads_user, nil)
    |> put_session(:goodreads_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.goodreads_user[uid_field]
  end

  @doc """
  Includes the credentials from the goodreads response.
  """
  def credentials(conn) do
    {token, secret} = conn.private.goodreads_token

    %Credentials{token: token, secret: secret}
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.goodreads_user

    %Info{
      email: user["email"],
      image: user["profile_image_url_https"],
      name: user["name"],
      nickname: user["screen_name"],
      description: user["description"],
      location: user["location"],
      urls: %{
        Goodreads: "https://goodreads.com/#{user["screen_name"]}",
        Website: user["url"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the goodreads callback.
  """
  def extra(conn) do
    {token, _secret} = get_session(conn, :goodreads_token)

    %Extra{
      raw_info: %{
        token: token,
        user: conn.private.goodreads_user
      }
    }
  end

  defp fetch_user(conn, token) do
    params = [{"include_entities", false}, {"skip_status", true}, {"include_email", true}]

    case Goodreads.OAuth.get("/1.1/account/verify_credentials.json", params, token) do
      {:ok, %{status_code: 401, body: _, headers: _}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %{status_code: status_code, body: body, headers: _}} when status_code in 200..399 ->
        conn
        |> put_private(:goodreads_token, token)
        |> put_private(:goodreads_user, body)

      {:ok, %{status_code: _, body: body, headers: _}} ->
        error = List.first(body["errors"])
        set_errors!(conn, [error("token", error["message"])])
    end
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options
    |> Keyword.get(key, default)
  end
end
