Streamz
=======

NOTE: Many of the stream sources previously in this repo have been moved into <https://github.com/hamiltop/structurez>

# Dataflow and Reactive Programming

## Highlights

### `Streamz.merge/1`
`Streamz.merge/1` accepts an array of streams and merges them into a single stream. This differs from `Stream.zip/2` in that the resulting order is a function of execution order rather than simply alternating between the two streams.

#### Merge two GenEvent streams and take the first 100 events from either

```elixir
{:ok, event_one} = GenEvent.start_link
{:ok, event_two} = GenEvent.start_link
combined_stream = Streamz.merge [
  GenEvent.stream(event_one),
  GenEvent.stream(event_two)
]
combined_stream |> Enum.take(100)
```

### `Streamz.Task.stream/1`
`Streamz.Task.stream/1` accepts an array of functions and launches them all as Tasks. The returned stream will emit the results of the Tasks in the order in which execution completes.

```elixir
stream = Streamz.Task.stream [
  fn ->
    :timer.sleep(10)
    1
  end, 
  fn -> 2 end
]
result = stream |> Enum.to_list
assert result == [2,1]
```

This enables a lot of cool functionality, such as processing just the first response:

```elixir
result = stream |> Enum.take(1) |> hd
```

The above example is so useful it exists as `Streamz.Task.first_completed_of/1`

More ideas are welcome. Feedback on code quality is welcomed, especially when it comes to OTP fundamentals (eg. monitoring vs linking).

## Production readiness
This is largely a playground at the moment, but the plan is to get this mature enough to be used in production. Some more tests and a bit more use will help with stability and my ability to commit to the APIs of the library.
