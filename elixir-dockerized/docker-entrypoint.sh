#!/bin/sh
set -e

# Set up distributed Erlang with proper DNS resolution
export CONTAINER_IP=$(hostname -i)
export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=$NODE_NAME

# Set the Erlang cookie
export RELEASE_COOKIE=$ERLANG_COOKIE
echo "Using cookie: $RELEASE_COOKIE for node $RELEASE_NODE"

# If worker, connect to master node after a delay
if [ "$NODE_TYPE" = "worker" ]; then
  echo "Worker node starting, will connect to $MASTER_NODE"
  (sleep 10 && elixir --name $NODE_NAME --cookie $ERLANG_COOKIE -e "IO.puts(\"Connecting to \#{System.get_env(\"MASTER_NODE\")}...\"); Node.connect(String.to_atom(System.get_env(\"MASTER_NODE\"))); IO.puts(\"Connected nodes: \#{inspect(Node.list())}\")") &
elif [ "$NODE_TYPE" = "master" ]; then
  echo "Master node starting"
fi

# Run the passed command
exec "$@"