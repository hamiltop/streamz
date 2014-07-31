defmodule GroupedStreamConfig do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def get_stream(pid, key) do
    GenServer.call(pid, {:get_stream, key})
  end

  def get_all_streams(pid) do
    GenServer.call(pid, :get_all_streams)
  end

  def subscribe(pid, key) do
    GenServer.call(pid, {:subscribe, key})
  end

  def unsubscribe(pid, key) do
    GenServer.call(pid, {:unsubscribe, key})
  end

  # GenServer callbacks

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:get_stream, key}, _from, state) do
    {:reply, state[key], state}
  end

  def handle_call(:get_all_streams, _from, state) do
    {:reply, Dict.values(state), state}
  end

  def handle_call({:subscribe, key}, {pid,ref}, state) do
    case state[key] do
      nil ->
        {:reply, :ok, Dict.put(state, key, pid)}
      _   ->
        {:reply, :key_in_use, state}
    end
  end

  def handle_call({:unsubscribe, key}, from, state) do
    case state[key] do
      ^from ->
        {:reply, :ok, Dict.delete(state, key)}
      _   ->
        {:reply, :key_not_found, state}
    end
  end
end
