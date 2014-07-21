defmodule MergeTest do
  use ExUnit.Case

  test "infinite streams" do
    stream_one = Stream.cycle [1,2,3]
    stream_two = Stream.cycle [3,4,5]
    stream_three = Streamz.merge([stream_one, stream_two])
    values = stream_three |> Enum.take(10)
    assert values |> Enum.member?(1)
    assert values |> Enum.member?(5)
    assert Enum.count(values) == 10
  end

  test "finite streams" do
    stream_one = [1,2,3]
    stream_two = [3,4,5]
    stream_three = Streamz.merge([stream_one, stream_two])
    values = stream_three |> Enum.take(10)
    assert values |> Enum.member?(1)
    assert values |> Enum.member?(5)
    assert Enum.count(values) ==  6
  end

  test "mixed streams" do
    stream_one = [1,2,3]
    stream_two = Stream.cycle [3,4,5]
    stream_three = Streamz.merge([stream_one, stream_two])
    values = stream_three |> Enum.take(10)
    assert values |> Enum.member?(1)
    assert values |> Enum.member?(5)
    assert Enum.count(values) == 10
  end

  test "GenEvent streams" do
    {:ok, event_one} = GenEvent.start_link
    {:ok, event_two} = GenEvent.start_link
    events = [event_one, event_two]
    task = Task.async fn ->
      stream = Streamz.merge(events |> Enum.map &GenEvent.stream(&1) )
      stream |> Enum.take(10)
    end
    1..10 |> Enum.each fn(x) ->
      :timer.sleep(10) # sufficient sleep to preserve ordering
      event = Enum.shuffle(events) |> hd
      GenEvent.notify(event, x)
    end
    results = Task.await(task)
    assert results == [1,2,3,4,5,6,7,8,9,10]
  end
end
