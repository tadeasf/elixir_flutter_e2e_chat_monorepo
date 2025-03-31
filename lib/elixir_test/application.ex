defmodule ElixirTest.Application do
  use Application
  require Logger

  def start(_type, _args) do
    # Configure libcluster topology based on environment
    topologies = Application.get_env(:libcluster, :topologies, [])

    children = [
      # Clustering supervisor for horizontal scaling
      {Cluster.Supervisor, [topologies, [name: ElixirTest.ClusterSupervisor]]},

      # Database Supervisor (critical system - if it fails, everything should restart)
      %{
        id: ElixirTest.DatabaseSupervisor,
        start: {Supervisor, :start_link, [[
          {Mongo, [
            name: :mongo,
            database: "elixir_test",
            pool_size: System.schedulers_online() * 2,
            url: "mongodb://root:rootpassword@localhost:27017/elixir_test?authSource=admin"
          ]},
          {ElixirTest.Database.DatabaseWorker, []}
        ], [strategy: :one_for_all, name: ElixirTest.DatabaseSupervisor]]}
      },

      # Auth Supervisor (if auth fails, only auth-related processes should restart)
      %{
        id: ElixirTest.AuthSupervisor,
        start: {Supervisor, :start_link, [[
          {ElixirTest.Auth, []}
        ], [strategy: :one_for_one, name: ElixirTest.AuthSupervisor]]}
      },

      # HTTP Server Supervisor
      %{
        id: ElixirTest.HttpSupervisor,
        start: {Supervisor, :start_link, [[
          {Plug.Cowboy,
            scheme: :http,
            plug: ElixirTest.Router,
            options: [
              port: 4000,
              protocol_options: [max_keepalive: 5_000_000],
              transport_options: [num_acceptors: System.schedulers_online()]
            ]
          }
        ], [strategy: :one_for_one, name: ElixirTest.HttpSupervisor]]}
      },

      # Task Supervisor for all background operations
      {Task.Supervisor, name: ElixirTest.TaskSupervisor}
    ]

    Logger.info("Starting application with #{System.schedulers_online()} schedulers")

    # Use rest_for_one strategy - if database fails, everything after it should restart
    opts = [strategy: :rest_for_one, name: ElixirTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
