defmodule Streamz.CompoundStream do

  defstruct streams: []
end

defimpl Enumerable, for: Streamz.CompoundStream do

  def member?(_,_), do: {:error, __MODULE__}
  def count(_), do: {:error, __MODULE__}

  def reduce(stream, acc, reducer) do
    Stream.resource(
      fn -> start_stream(stream) end,
      &next/1,
      &stop/1
    ).(acc, reducer)
  end

  @spec start_stream(%Streamz.CompoundStream{}) :: pid
  defp start_stream(stream) do
    parent = self
    spawn_link fn ->
      stream.streams |> Enum.each &start_substream(&1, self)
      count = stream.streams |> Enum.count
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
    Process.exit(collector, "finished")
  end

  @spec start_substream(%Streamz.CompoundStream{}, pid) :: pid
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
