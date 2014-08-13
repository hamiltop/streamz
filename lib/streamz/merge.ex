defmodule Streamz.Merge do
  @moduledoc false

  require Streamz

  def build_merge_stream(streams) do
    Stream.resource(
      fn -> start_stream(streams) end,
      &next/1,
      &stop/1
    )
  end

  #@spec start_stream([Enumerable.t]) :: pid
  defp start_stream(streams) do
    ref = make_ref
    parent = self
    pids = streams |> Enum.map fn (stream) ->
      spawn_link fn ->
        stream |> Enum.each fn (el) ->
          {:ok, :ack} = :gen.call(parent, '$merge', {ref, {:value, el}}, :infinity)
        end
        {:ok, :ack} = :gen.call(parent, '$merge', {ref, :done}, :infinity)
      end
    end
    {ref, pids}
  end

  #@spec next(pid) :: {term, pid} | nil
  defp next({_, []}) do
    nil
  end
  defp next({ref, streams}) do
    receive do
      {'$merge', {pid, _} = from, {^ref, value}} ->
        case value do
          {:value, value} ->
            :gen.reply from, :ack
            {value, {ref, streams}}
          :done ->
            next({ref , List.delete(streams, pid)})
        end
    end
  end

  #@spec stop(pid) :: true
  defp stop({ref, streams}) do
    streams |> Enum.each fn(stream) ->
      mref = Process.monitor(stream)
      Process.unlink(stream)
      Process.exit(stream, :kill)
      receive do
        {:DOWN, ^mref, _, _, :killed} ->
      end
    end
    Streamz.clear_mailbox({'$merge', _, {^ref, _}})
  end
end
