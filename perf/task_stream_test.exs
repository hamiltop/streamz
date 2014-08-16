scale = Stream.iterate({1,1}, fn ({old, cur}) ->
  {cur, old + cur}
end) |> Stream.map(&elem(&1, 1)) |> Stream.drop(1_000_00)

IO.puts "New"

[1,2,3,5,8,13,21,34,55,89,144,233,377] |> Enum.each fn (count) ->
  {time, _} = :timer.tc fn ->
    funs = Stream.cycle([fn -> Enum.take(scale, 10) end]) |> Enum.take(count)
    Streamz.tasks(funs) |> Enum.take(count)
  end
  IO.puts "#{count}\t#{time}"
end

IO.puts "Old"

[1,2,3,5,8,13,21,34,55,89,144,233,377] |> Enum.each fn (count) ->
  {time, _} = :timer.tc fn ->
    funs = Stream.cycle([fn -> Enum.take(scale, 10) end]) |> Enum.take(count)
    Streamz.Task.stream(funs) |> Enum.take(count)
  end
  IO.puts "#{count}\t#{time}"
end
