defmodule Streamz.Merge do
  @moduledoc false

  def build_merge_stream(streams) do
    Stream.resource(
      fn -> start_stream(streams) end,
      &next/1,
      &stop/1
    )
  end

  @spec start_stream([Enumerable.t]) :: pid
  defp start_stream(streams) do
    parent = self
    spawn_link fn ->
      streams |> Enum.each &start_substream(&1, self)
      count = streams |> Enum.count
      wait_for_request(parent, count)
    end
  end

  @spec wait_for_request(pid, non_neg_integer) :: term
  defp wait_for_request(parent, count) do
    :ok = receive do
      :get -> :ok
    end
    collect(parent, count)
  end

  @spec collect(pid, non_neg_integer) :: term
  defp collect(parent, 0), do: send(parent, {:done, self})
  defp collect(parent, count) do
    result = receive do
      {:ok, pid, value} ->
        send(pid, {:ack, self})
        value
      :done ->
        collect(parent, count - 1)
    end
    send parent, {self, result}
    wait_for_request(parent, count)
  end

  @spec next(pid) :: {term, pid} | nil
  defp next(collector) do
    send collector, :get
    receive do
      {^collector, result} -> {result, collector}
      {:done, ^collector} ->
        nil
    end
  end

  @spec stop(pid) :: true
  defp stop(collector) do
    Process.unlink(collector)
    Process.exit(collector, :done)
  end

  @spec start_substream(Enumerable.t, pid) :: pid
  defp start_substream(stream, collector) do
    spawn_link fn ->
      stream |> Enum.each fn(value) ->
        send(collector, {:ok, self, value})
        receive do
          {:ack, ^collector} -> :ok
        end
      end
      send(collector, :done)
    end
  end

end
