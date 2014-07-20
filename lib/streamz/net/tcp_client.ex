defmodule Streamz.Net.TCPClient do
  @moduledoc """
  TCPClient contains convenience methods for creating TCPSocket streams.
  """

  @doc """
  Creates a TCPSocket stream after connecting to the passed in host and port

  Options (required):
  
  * `:host` - can be either a list or a bitstring
  * `:port` - integer representing the port to connect to
  """
  @spec stream([atom: ([integer] | integer | binary)]) :: %Streamz.Net.TCPSocket{}
  def stream(options) do
    host = case options[:host] do
      h when is_bitstring(h) -> String.to_char_list(h)
      h when is_list(h) -> h
    end
    port = options[:port]

    {:ok, socket} = :gen_tcp.connect(host, port, [active: false])
    %Streamz.Net.TCPSocket{socket: socket}
  end
end

