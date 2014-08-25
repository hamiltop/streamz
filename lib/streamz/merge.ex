defmodule Streamz.Merge do
  @moduledoc false

  defstruct streams: []

  require Streamz.Merge.Helpers
  require Connectable.Helpers

  alias Connectable.Helpers, as: H

  def new(streams) do
    %__MODULE__{streams: streams}
  end

  def build_merge_stream(stream) do
    Stream.resource(
      fn -> start_stream(stream.streams) end,
      &next/1,
      &stop/1
    )
  end

  @type merge_resource :: {reference, pid}

  @spec start_stream([Enumerable.t]) :: merge_resource
  defp start_stream(streams) do
    parent = self
    agent = create_state
    spawner = spawn_link fn ->
      connections = streams |> Enum.flat_map fn (stream) ->
        Connectable.connect(stream, parent)
      end
      set_sources(agent, connections)
      receive do
        H.pattern(from, :cleanup) ->
          Agent.get(agent, fn (%{sources: sources, completed: completed}) ->
            Set.difference(sources, completed)
          end) |> Enum.each fn({stream, id}) ->
            Connectable.disconnect(stream, id)
          end
          :gen.reply(from, :ack)
      end
    end
    {spawner, agent}
  end

  @spec next(merge_resource) :: {term, merge_resource} | nil
  defp next(state = {_, agent}) do
    receive do
      H.pattern(from, value) ->
        :gen.reply from, :ok
        case value do
          {:ack_notify, value} ->
            {[value], state}
          {:done, id} ->
            case add_completed_and_check_state(agent, id) do
              true -> {:halt, state}
              false -> next(state)
            end
        end
    end
  end

  @spec stop(merge_resource) :: :ok
  defp stop({spawner, _}) do
    {:ok, :ack} = H.call(spawner, :cleanup)
    Streamz.Merge.Helpers.clear_mailbox(H.pattern('$connect', _))
    :ok
  end

  defp create_state do
    {:ok, pid} = Agent.start_link fn ->
      %{started: false, sources: HashSet.new, completed: HashSet.new}
    end
    pid
  end

  defp set_sources(pid, sources) do
    Agent.update pid, fn(state) ->
      %{state | :started => true, :sources => Enum.into(sources, HashSet.new)}
    end
  end

  defp add_completed_and_check_state(pid, stream) do
    Agent.get_and_update pid, fn(state) ->
      new_state = %{state | :completed => Set.put(state.completed, stream)}
      done = new_state[:started] && Set.equal?(new_state[:completed], new_state[:sources])
      {done, new_state}
    end
  end
end

defprotocol Mergeable do
  @fallback_to_any true
  @type id :: term
  @spec merge(Enumerable.t, pid, reference) :: [id]
  def merge(stream, target, ref)

  @spec cleanup(Enumerable.t, id) :: :ok
  def cleanup(stream, id)
end

defimpl Mergeable, for: Streamz.Merge do

  defdelegate cleanup(stream, id), to: Mergeable.Any

  def merge(stream, target, ref) do
    stream.streams |> Enum.flat_map fn(str) ->
      Mergeable.merge(str, target, ref)
    end
  end
end

defimpl Enumerable, for: Streamz.Merge do
  def reduce(stream, acc, fun) do
    Streamz.Merge.build_merge_stream(stream).(acc, fun)
  end

  def count(_), do: {:error, __MODULE__}

  def member?(_, _), do: {:error, __MODULE__}
end
