defmodule Streamz.Net.TCP do
  defstruct socket: nil

  def stream(options) do
    host = case options[:host] do
      h when is_bitstring(h) -> String.to_char_list(h)
      h when is_list(h) -> h
    end
    port = options[:port]

    {:ok, socket} = :gen_tcp.connect(host, port, [active: false])
    %__MODULE__{socket: socket}
  end

  defimpl Enumerable, for: __MODULE__ do
    def reduce(stream, acc, reducer) do
      Stream.unfold(
        stream,
        fn (stream) ->
          case next(stream) do
            {:ok, value} -> {value, stream}
            _ -> nil
          end
        end
      ).(acc, reducer)
    end

    defp next(stream) do
      stream.socket |> :gen_tcp.recv(0)
    end

    def member?(_,_), do: {:error, __MODULE__}
    def count(_), do: {:error, __MODULE__}
  end

  defimpl Collectable, for: __MODULE__ do
    def into(stream) do
      {:ok, fn
          :ok, {:cont, x} -> write(stream, x)
          :ok, _ -> stream
      end}
    end

    defp write(stream, data) do
      :ok = stream.socket |> :gen_tcp.send(data)
    end

    def empty(stream), do: stream
  end
end
