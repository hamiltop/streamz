defmodule GroupedStream do
  use GenServer

  def start_link(stream, key, opts \\ []) do
    GenServer.start_link(__MODULE__, [source: stream.consumer, config: stream.config, key: key], opts)
  end

  def next(pid) do
    GenServer.call(pid, :next)
  end

  # GenServer callbacks

  def init([source: source, config: config, key: key]) do
    GroupedStreamConfig.subscribe(config, key)
    {:ok, %{source: source, config: config, key: key, data: []}}
  end

  def handle_call(:next, _from, state = %{data: []}) do
    value = case check_inbox do
      :none ->
        send state[:source], {:next, state[:key]}
        receive do
          {:data, data} -> data
          :done -> :done
        end
      {:data, data} -> data
    end

    {:reply, value, state}
  end

  def handle_call(:next, _from, state = %{data: [h | t]}) do
    {:reply, h, %{state | :data => t}}
  end

  def handle_info({:data, value}, state) do
    {:noreply, %{ state | :data => (state[:data] ++ [value])}}
  end

  def handle_info(:done, state) do
    {:noreply, state}
  end

  defp check_inbox do
    receive do
      {:data, data} -> {:data, data}
    after
      0 -> :none
    end
  end
end
