[1] |> Enum.each fn (_) ->
  {:ok, event_one} = GenEvent.start_link
  {:ok, event_two} = GenEvent.start_link
  events = [event_one, event_two]
  task = Task.async fn ->
    :timer.sleep(100)
    Stream.cycle([:ok]) |> Stream.take(1_000_000) |> Enum.each fn (_) ->
      Enum.each(events, &(GenEvent.ack_notify(&1, :hi)))
    end
  end
  {time, _} = :timer.tc fn ->
    IO.inspect Enum.count(:erlang.processes)
    task = Task.async fn ->
      Streamz.merge(events |> Enum.map &GenEvent.stream(&1) ) |> Enum.take(1_000_000)
    end
    :timer.sleep(1000)
    IO.inspect Enum.count(:erlang.processes)
    Task.await(task, 100_000)
  end
  IO.puts time
  IO.inspect spawn fn -> :ok end
  #Task.await(task, :infinity)
end
