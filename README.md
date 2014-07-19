Streamz
=======

## Stream all the things

Everything can and should be streamed. This library is an attempt to make standard Erlang/Elixir things into Streams.

## Highlights

`Streamz.merge/1` accepts an array of streams and merges them into a single stream. This differs from Stream.zip/2 in that the resulting order is a function of execution order rather than alternating.

### Merge two GenEvent streams and take the first 100 events from either

```elixir
{:ok, event_one} = GenEvent.start_link
{:ok, event_two} = GenEvent.start_link
combined_stream = Streamz.merge [
  GenEvent.stream(event_one),
  GenEvent.stream(event_two)
]
combined_stream |> Enum.take(100)
```

`Streamz.Net.TCPClient.stream/1` accepts a keyword list with `:host` and `:port` set. It will connect the the host and port and supports Enumerable and Collectable. This enables a bunch of cool things.

### Connecting:

```elixir
n = Streamz.Net.TCPClient.stream([host: "localhost", port: 4444])
```

### Reading data:

```elixir
n |> Enum.each &IO.inspect(&1)
```

### Writing data:

```elixir
["Hello", "World"] |> Enum.into(n)
```

### Echo Client (writes any data it receives back to the server):

```elixir
n |> Enum.into(n)
```

## Up Next
There are tons of possibilities for Streamz. Here's what's on the current radar.

- `Streamz.Net.TCPServer/1` - A server version of `Streamz.Net.TCPClient`
- `Streamz.Net.UDPClient/1` - A UDP version of `Streamz.Net.TCPClient`
- `Streamz.Net.UDPServer/1` - A server version of `Streamz.Net.TCPClient`
- `Streamz.Task.stream/1` - Accepts an array of functions and streams the result of the functionsin the order of completion.

More ideas are welcome.

## Production readiness
This is largely a playground at the moment, but the plan is to get this mature enough to be used in production. Some more tests and a bit more use will help with stability and my ability to commit to the APIs of the library.
