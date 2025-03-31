defmodule ElixirTest.Auth do
  use GenServer
  use Joken.Config

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def generate_token(user_id) do
    GenServer.call(__MODULE__, {:generate_token, user_id})
  end

  def verify_token(token) do
    GenServer.call(__MODULE__, {:verify_token, token})
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:generate_token, user_id}, _from, state) do
    extra_claims = %{"user_id" => user_id}
    {:ok, token, _claims} = generate_and_sign(extra_claims)
    {:reply, token, state}
  end

  @impl true
  def handle_call({:verify_token, token}, _from, state) do
    result = case verify_and_validate(token) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
    {:reply, result, state}
  end

  @impl true
  def token_config do
    default_claims(
      default_exp: 24 * 60 * 60
    )
  end
end
