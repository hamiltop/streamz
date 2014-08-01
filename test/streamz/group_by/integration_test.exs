defmodule GroupedIntegrationTest do
  use ExUnit.Case

  test "properly groups stream" do
    {:ok, s} = GenEvent.start_link
    stream = GenEvent.stream(s)
    g = Streamz.group_by(stream, fn (el) -> rem(el, 5) end)
    ones = Task.async fn ->
      g[1] |> Enum.take(3)
    end
    twos = Task.async fn ->
      g[2] |> Stream.map(fn (el) ->
        :timer.sleep(50) # delay long enough to cause buffering
        el
      end) |> Enum.take(3)
    end
    :timer.sleep(10) # give a few ms for the Tasks to launch
    GenEvent.notify(s, 0)
    GenEvent.notify(s, 1)
    GenEvent.notify(s, 2)
    GenEvent.notify(s, 0)
    GenEvent.notify(s, 6)
    GenEvent.notify(s, 7)
    GenEvent.notify(s, 6)
    GenEvent.notify(s, 12)
    assert Task.await(ones) == [1,6,6]
    assert Task.await(twos) == [2,7,12]
  end

  test "works with finite streams" do
    g = Streamz.group_by([1,2,3], fn (el) -> rem(el, 5) end)
    ones = Task.async fn ->
      g[1] |> Enum.take(3)
    end
    assert Task.await(ones) == [1]
  end
end
