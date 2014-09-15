defprotocol EventSource do
  @moduledoc """
  EventSource defines a protocol for data structures that are able to send events (messages) to other process as specified by the GenEvent protocol.

  `add_handler/2` receives the data structure and a process (handler) to send the events to.
  
  `remove_handler/2` removes a previously registered process.

  In case a data structure does not implement Notifiable but is an Enumerable, the data is automatically traversed and each item in the data structure is sent as a notification from a spawned process.

  ## Messages

  Once a process is added as recipient via `add_handler/3`, the Notifiable data structure will send events to it using one of the three following messages:

  * {pid, {ref, pid}, {:notify, event}} - an async event. the client does not need to respond
  * {pid, {ref, pid}, {:sync_notify, event}} - an sync event. the client must reply with {ref, :ok} or {ref, :done} after the event is processed
  * {pid, {ref, pid}, {:ack_notify, event}} - an ack event. the client must reply with {ref, :ok} or {ref, :done} as soon as the event is received

  Once there are no more events to be sent, a {:gen_event_EXIT, pid, reason} message must be sent to the added process, where reason is often :normal (no more events) or :shutdown (process is shutting down).
  """
  @fallback_to_any true

  @doc """
  Add target pid as a handler.
  
  The only supported options is `mode` which can be one of:

  * :sync - send `:sync_notify` events, requiring the client to fully process the element before acknowledging
  * :async - send `:notify` events, without waiting for the previous event to be acknowledged
  * :ack - send `:ack_notify` events, requiring the client to acknowledge as soon as the event is received
  """
  def add_handler(source, target)
  def remove_handler(source, pid)
end

defmodule EventSource.Connection do
  defstruct pid: nil, data: nil
end

defimpl EventSource, for: Any do
  def add_handler(source, target) do
    mode = :ack

    notify = case mode do
      :async -> :notify
      :ack   -> :ack_notify
      :sync  -> :sync_notify
    end

    pid = spawn fn ->
      ref = make_ref
      Enum.each source, fn (el) ->
        send target, {self, {self, ref}, {notify, el}}
        case mode do
          x when x in [:ack, :sync] ->
            receive do
              {^ref, :ok} -> :ok
              {^ref, :done} -> :done
            end
          :async -> :ok
        end
      end
    end
    [%EventSource.Connection{pid: pid}]
  end

  def remove_handler(_source, %EventSource.Connection{pid: pid}) do
    Process.exit pid, :kill
  end
end

defimpl EventSource, for: GenEvent.Stream do
  def add_handler(manager, target) do
    {:ok, ref} = :gen.call(manager.manager, target, {:add_process_handler, target, target, nil}, :infinity)
    [%EventSource.Connection{data: %{ref: ref}}]
  end

  def remove_handler(manager, connection) do
  end
end
