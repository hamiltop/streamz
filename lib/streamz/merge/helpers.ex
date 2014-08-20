defmodule Streamz.Merge.Helpers do
  def call(target, ref, message, timeout \\ 5000) do
    :gen.call(target, '$merge', {ref, message}, timeout)
  end

  defmacro pattern(from, ref, message) do
    quote do
      {'$merge', unquote(from), {^unquote(ref), unquote(message)}}
    end
  end

  @doc """
  A helper macro for clearing out messages that match a certain pattern from an inbox.
  """
  defmacro clear_mailbox(pattern) do
    quote do
      fun1 = fn(fun2, count) ->
        receive do
          unquote(pattern) -> fun2.(fun2, count+1)
        after
          0 -> count
        end
      end
      fun1.(fun1, 0)
    end
  end
end
