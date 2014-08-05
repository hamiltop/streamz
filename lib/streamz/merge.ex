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
    {:ok, collector} = Streamz.Merge.Collector.start_link(streams)
    collector
  end

  @spec next(pid) :: {term, pid} | nil
  defp next(collector) do
    case Streamz.Merge.Collector.get_value(collector) do
      {:value, value} -> {value, collector}
      :done -> nil
    end
  end

  @spec stop(pid) :: true
  defp stop(collector) do
    Streamz.Merge.Collector.stop(collector)
  end
end
