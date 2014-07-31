defmodule StreamConsumer do
  
  def start_link(stream, fun, config_server) do
    pid = spawn_link fn ->
      stream |> Enum.reduce HashSet.new, fn (el, acc) ->
        if HashSet.size(acc) == 0 do
          new_set = idle()
          process_data(el, new_set, fun, config_server)
        else
          process_data(el, acc, fun, config_server)
        end
      end
      GroupedStreamConfig.get_all_streams(config_server) |> Enum.each fn (pid) ->
        send pid, :done
      end
    end
    {:ok, pid}
  end

  @spec idle() :: HashSet.t
  defp idle() do
    receive do
      {:next, key} ->
        Enum.into [key], HashSet.new()
    end
  end

  @spec process_data(term, HashSet.t, (term -> term), pid) :: HashSet.t
  defp process_data(el, keys, fun, config_server) do
    key = fun.(el)
    case GroupedStreamConfig.get_stream(config_server, key) do
      nil ->
        keys
      grouped_stream_pid ->
        send grouped_stream_pid, {:data, el}
        Set.delete(keys, key)   
    end
  end

end
