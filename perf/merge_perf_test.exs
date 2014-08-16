scale = Stream.iterate({1,1}, fn ({old, cur}) ->
  {cur, old + cur}
end) |> Stream.map &elem(&1, 1)

Stream.take(scale, 20) |> Stream.map(fn(count) ->
  streams = Stream.cycle([1..1_000_000_000]) |> Stream.take(count)
  results = 1..5 |> Enum.map(fn(_) ->
    :timer.tc(fn ->
      Streamz.merge(streams) |> Enum.take(1_000_000)
    end) |> elem(0)
  end)
  {results, count}
end) |> Enum.each fn({times, index}) -> IO.puts "#{index}\t#{Enum.join(times, "\t")}" end
