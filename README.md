# Überauth Goodreads

> Goodreads strategy for Überauth.

_Note_: Sessions are required for this strategy.

## Installation

1. Setup your application at [Goodreads API](https://goodreads.com/api).

1. Add `:ueberauth_goodreads` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:ueberauth_goodreads, "https://github.com/mrbberra/ueberauth_goodreads.git"}
      ]
    end
    ```

1. Add Goodreads to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        goodreads: {Ueberauth.Strategy.Goodreads, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Goodreads.OAuth,
      consumer_key: System.get_env("GOODREADS_CONSUMER_KEY"),
      consumer_secret: System.get_env("GOODREADS_CONSUMER_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/goodreads

## Development mode

As noted when registering your application on the Goodreads Developer site, you need to explicitly specify the `oauth_callback` url.  While in development, this is an example url you need to enter.

    Website - http://127.0.0.1
    Callback URL - http://127.0.0.1:4000/auth/goodreads/callback

## License

Please see [LICENSE](https://github.com/mrbberra/ueberauth_goodreads/blob/master/LICENSE) for licensing details.

