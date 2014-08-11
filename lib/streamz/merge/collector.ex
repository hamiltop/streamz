defmodule Streamz.Merge.Collector do
  @moduledoc false
  use GenServer

  # Client
  def start_link(streams) do
    GenServer.start_link(__MODULE__, streams)
  end

  def send_value(pid, value) do
    {:ack, target} = GenServer.call(pid, :value, :infinity)
    GenServer.reply(target, {:value, value})
  end

  def send_done(pid) do
    GenServer.call(pid, :done)
  end

  def get_value(pid) do
    GenServer.call(pid, :get, :infinity)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  # Server
  def init(streams) do
    collector = self
    # launch all the substream processes
    stream_pids = streams |> Enum.map fn(stream) ->
      spawn_link fn ->
        stream |> Enum.each fn(value) ->
          Streamz.Merge.Collector.send_value(collector, value)
        end
        Streamz.Merge.Collector.send_done(collector)
      end
    end
    {:ok, %{producers: [], consumers: [], streams: stream_pids}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :done, state}
  end

  def handle_call(:get, _from, state = %{consumers: [], streams: [], producers: []}) do
    {:reply, :done, state}
  end

  def handle_call(:get, from, state = %{consumers: [], producers: []}) do
    {:noreply, %{state | :consumers => state.consumers ++ [from]}}
  end

  def handle_call(:get, from, state = %{producers: [h | t]}) do
    GenServer.reply(h, {:ack, from})
    {:noreply, %{state | :producers => t}}
  end

  def handle_call(:value, from, state = %{consumers: []}) do
    {:noreply, %{state | :producers => state.producers ++ [from]}}
  end

  def handle_call(:value, _from, state = %{consumers: [h | t]}) do
    {:reply, {:ack, h}, %{state | :consumers => t}}
  end

  def handle_call(:done, {pid, _ref}, state = %{consumers: []}) do
    streams = List.delete(state.streams, pid)
    {:reply, :ok, %{state | :streams => streams}}
  end

  def handle_call(:done, {pid, _ref}, state) do
    streams = List.delete(state.streams, pid)
    if length(streams) == 0 do
      state.consumers |> Enum.each &GenServer.reply(&1, :done)
    end
    {:reply, :ok, %{state | :streams => streams}}
  end
end
