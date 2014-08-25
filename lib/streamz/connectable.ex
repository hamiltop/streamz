defmodule Connectable.Helpers do

  def call(target, message, timeout \\ 5000) do
    :gen.call(target, '$connect', message, timeout)
  end

  defmacro pattern(from, message) do
    quote do
      {_, unquote(from), unquote(message)}
    end
  end
end

defprotocol Connectable do
  @fallback_to_any true

  @type t :: any
  @type connection :: any

  @spec connect(t, pid) :: [connection]
  def connect(source, target)

  @spec disconnect(t, connection) :: :ok
  def disconnect(source, connection)
end

defimpl Connectable, for: Any do

  alias Connectable.Helpers, as: H

  def connect(stream, target) do
    id = spawn_link fn ->
      stream |> Enum.each fn(el) ->
        {:ok, :ok} = H.call(target, {:ack_notify, el}, :infinity)
      end
      {:ok, :ok} = H.call(target, {:done, {stream, self}}, :infinity)
    end
    [{stream, id}]
  end

  def disconnect(_, pid) do
    mref = Process.monitor(pid)
    Process.unlink(pid)
    Process.exit(pid, :kill)
    receive do
      {:DOWN, ^mref, _, _, :killed} ->
    end
  end
end

defimpl Connectable, for: Streamz.Merge do

  defdelegate disconnect(stream, connection), to: Connectable.Any

  def connect(stream, target) do
    stream.streams |> Enum.flat_map fn(str) ->
      Connectable.connect(str, target)
    end
  end
end

defimpl Connectable, for: GenEvent.Stream do
  def connect(stream, target) do
    {:ok, msg_ref} = :gen.call(stream.manager, self(), {:add_process_handler, target, true}, :infinity)
    [{stream, msg_ref}]
  end

  def disconnect(_, _) do
    nil # something needs to happen here
  end
end
