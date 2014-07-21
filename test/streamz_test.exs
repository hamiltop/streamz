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
end
