# ElixirPhoenixChat

A chat API built with Elixir and Phoenix Framework, using MongoDB for persistence.

## Environment Setup

1. Copy `.env.example` to `.env` and adjust values as needed
   ```
   cp .env.example .env
   ```

2. Load environment variables (required before starting the server)
   ```
   source ./load_env.sh
   ```

## Development

To start your Phoenix server locally:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
API documentation is available at [`localhost:4000/api/swagger`](http://localhost:4000/api/swagger).

## Docker Deployment

To run the application with Docker:

```
docker-compose up -d
```

This will start both MongoDB and the Phoenix application with the configured environment variables.

## Flutter Client

The frontend Flutter application in the `../frontend` directory can be used to interact with this API.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
