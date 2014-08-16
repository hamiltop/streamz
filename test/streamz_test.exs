defmodule StreamzTest do
  use ExUnit.Case

  test "take_until/2" do
    {:ok, event_one} = GenEvent.start_link
    {:ok, event_two} = GenEvent.start_link
    stream = GenEvent.stream(event_one)
    cutoff = GenEvent.stream(event_two)
    task = Task.async fn ->
      Streamz.take_until(stream, cutoff) |> Enum.to_list
    end
    :timer.sleep(10)
    GenEvent.sync_notify(event_one, 1)
    GenEvent.sync_notify(event_one, 2)
    GenEvent.sync_notify(event_one, 3)
    GenEvent.sync_notify(event_two, 4)
    GenEvent.sync_notify(event_one, 5)
    assert Task.await(task) == [1,2,3]
  end

  test "combine_latest/2" do
    {:ok, left_event} = GenEvent.start_link
    {:ok, right_event} = GenEvent.start_link
    left_stream = GenEvent.stream(left_event)
    right_stream = GenEvent.stream(right_event)

    combined = Task.async fn ->
      Streamz.combine_latest(left_stream, right_stream)
      |> Stream.map(fn {a,b} -> %{:color => a.color, :shape => b.shape} end)
      |> Enum.take(4)
    end

    :timer.sleep(10)

    GenEvent.sync_notify(left_event, %{:color => "red", :shape => "triangle"})
    GenEvent.sync_notify(right_event, %{:color => "yellow", :shape => "square"})
    GenEvent.sync_notify(left_event, %{:color => "blue", :shape => "triangle"})
    GenEvent.sync_notify(right_event, %{:color => "red", :shape => "circle"})
    GenEvent.sync_notify(left_event, %{:color => "green", :shape => "rectangle"})

    assert Task.await(combined) == [
      %{color: "red", shape: "square"},
      %{color: "blue", shape: "square"},
      %{color: "blue", shape: "circle"},
      %{color: "green", shape: "circle"}
    ]
  end

  test "once/1" do
    s = Streamz.once fn ->
      :foo
    end
    assert Enum.take(s,2) == [:foo]
  end

  test "take_and_continue/3" do
    s = 1..100 |> Streamz.take_and_continue(10, fn(list) ->
      assert list == Enum.to_list(1..10)
    end) |> Enum.take(10)
    assert s == Enum.to_list(11..20)
  end
end
