defmodule Streamz.Merge do
  @moduledoc false

  require Streamz

  defmodule State do
    def new do
      {:ok, pid} = Agent.start_link fn ->
        %{started: false, sources: HashSet.new, completed: HashSet.new}
      end
      pid
    end

    def set_sources(pid, sources) do
      Agent.update pid, fn(state) ->
        %{state | :started => true, :sources => Enum.into(sources, HashSet.new)}
      end
    end

    def add_completed_and_check_state(pid, stream) do
      Agent.get_and_update pid, fn(state) ->
        new_state = %{state | :completed => Set.put(state.completed, stream)}
        done = new_state[:started] && Set.equal?(new_state[:completed], new_state[:sources])
        {done, new_state}
      end
    end
  end

  def build_merge_stream(streams) do
    Stream.resource(
      fn -> start_stream(streams) end,
      &next/1,
      &stop/1
    )
  end

  @type merge_resource :: {reference, pid}

  @spec start_stream([Enumerable.t]) :: merge_resource
  defp start_stream(streams) do
    ref = make_ref
    parent = self
    agent = State.new
    spawn_link fn ->
      pids = streams |> Enum.map fn (stream) ->
        spawn_link fn ->
          stream |> Enum.each fn (el) ->
            {:ok, :ack} = :gen.call(parent, '$merge', {ref, {:value, el}}, :infinity)
          end
          {:ok, :ack} = :gen.call(parent, '$merge', {ref, :done}, :infinity)
        end
      end
      State.set_sources(agent, pids)
    end
    {ref, agent}
  end

  @spec next(merge_resource) :: {term, merge_resource} | nil
  defp next({ref, agent}) do
    receive do
      {'$merge', {pid, _} = from, {^ref, value}} ->
        case value do
          {:value, value} ->
            :gen.reply from, :ack
            {value, {ref, agent}}
          :done ->
            :gen.reply from, :ack
            case State.add_completed_and_check_state(agent, pid) do
              true -> nil
              false -> next({ref, agent})
            end
        end
    end
  end

  @spec stop(merge_resource) :: :ok
  defp stop({ref, agent}) do
    Agent.get(agent, fn (%{sources: sources, completed: completed}) ->
      Set.difference(sources, completed)
    end) |> Enum.each fn(stream) ->
      mref = Process.monitor(stream)
      Process.unlink(stream)
      Process.exit(stream, :kill)
      receive do
        {:DOWN, ^mref, _, _, :killed} ->
      end
    end
    Streamz.clear_mailbox({'$merge', _, {^ref, _}})
    :ok
  end
end
