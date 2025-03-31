defmodule ElixirPhoenixChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirPhoenixChatWeb.Telemetry,
      # MongoDB setup - replace Postgres repo
      %{
        id: :mongo,
        start: {Mongo, :start_link, [[
          name: :mongo,
          database: "elixir_chat",
          pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2"),
          url: System.get_env("MONGODB_URL") || "mongodb://root:rootpassword@localhost:27017/elixir_chat?authSource=admin"
        ]]}
      },
      ElixirPhoenixChat.Repo,
      # Auth module for JWT management
      ElixirPhoenixChat.Auth,
      {DNSCluster, query: Application.get_env(:elixir_phoenix_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirPhoenixChat.PubSub},
      # Start the Task Supervisor for background tasks
      {Task.Supervisor, name: ElixirPhoenixChat.TaskSupervisor},
      # Start to serve requests, typically the last entry
      ElixirPhoenixChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirPhoenixChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirPhoenixChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
