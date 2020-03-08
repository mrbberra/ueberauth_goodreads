defmodule Ueberauth.Strategy.Goodreads.OAuth do
  @moduledoc """
  OAuth1 for Goodreads.

  Add `consumer_key` and `consumer_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Goodreads.OAuth,
    consumer_key: System.get_env("GOODREADS_CONSUMER_KEY"),
    consumer_secret: System.get_env("GOODREADS_CONSUMER_SECRET"),
    redirect_uri: System.get_env("GOODREADS_REDIRECT_URI")
  """

  alias Ueberauth.Strategy.Goodreads.OAuth.Internal

  @defaults [access_token: "/oauth/access_token",
             authorize_url: "/oauth/authorize",
             request_token: "/oauth/request_token",
             site: "https://goodreads.com"]

  defmodule ApiError do
    @moduledoc "Raised on OAuth API errors."

    defexception [:message, :code]

    def message(e = %{code: nil}), do: e.message

    def message(e) do
      "#{e.message} (Code #{e.code})"
    end
  end

  def access_token({token, token_secret}, verifier, opts \\ []) do
    opts
    |> client()
    |> to_url(:access_token)
    |> Internal.get([{"oauth_verifier", verifier}], consumer(client()), token, token_secret)
    |> decode_response
  end

  def access_token!(access_token, verifier, opts \\ []) do
    case access_token(access_token, verifier, opts) do
      {:ok, token} -> token
      {:error, error} -> raise error
    end
  end

  def authorize_url!({token, _token_secret}, opts \\ []) do
    opts
    |> client()
    |> to_url(:authorize_url, %{"oauth_token" => token})
  end

  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__)

    @defaults
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
    |> Enum.into(%{})
  end

  def get(url, access_token), do: get(url, [], access_token)
  def get(url, params, {token, token_secret}) do
    client()
    |> to_url(url)
    |> Internal.get(params, consumer(client()), token, token_secret)
  end

  def request_token(params \\ [], opts \\ []) do
    client = client(opts)
    params = [{"oauth_callback", client.redirect_uri} | params]

    client
    |> to_url(:request_token)
    |> Internal.get(params, consumer(client))
    |> decode_response
  end

  def request_token!(params \\ [], opts \\ []) do
    case request_token(params, opts) do
      {:ok, token} -> token
      {:error, error} -> raise error
    end
  end

  defp consumer(client), do: {client.consumer_key, client.consumer_secret, :hmac_sha1}

  defp decode_response({:ok, %{status_code: 200, body: body}}) do
    params = Internal.params_decode(body)
    token = Internal.token(params)
    token_secret = Internal.token_secret(params)

    {:ok, {token, token_secret}}
  end

  defp decode_response({:ok, %{status_code: status_code, body: body}}) do
    error_message = Regex.scan(~r"(.*?)\n.*", body, capture: :all_but_first)
    {:error, %ApiError{message: error_message, code: status_code}}
  end

  defp decode_response({:error, %{reason: reason}}) do
    {:error, "#{reason}"}
  end

  defp decode_response(error) do
    {:error, error}
  end

  defp endpoint("/" <> _path = endpoint, client), do: client.site <> endpoint
  defp endpoint(endpoint, _client), do: endpoint

  defp to_url(client, endpoint, params \\ nil) do
    endpoint =
      client
      |> Map.get(endpoint, endpoint)
      |> endpoint(client)

    endpoint =
      if params do
        endpoint <> "?" <> URI.encode_query(params)
      else
        endpoint
      end

    endpoint
  end
end
