defmodule GroupedIntegrationTest do
  use ExUnit.Case

  test "do it" do
    {:ok, s} = GenEvent.start_link
    stream = GenEvent.stream(s)
    g = Streamz.group_by(stream, fn (el) -> rem(el, 5) end)
    spawn_link fn ->
      g[1] |> Enum.each fn(el) ->
        IO.puts "Got #{el}"
      end
    end
    spawn_link fn ->
      g[0] |> Enum.each fn(el) ->
        :timer.sleep(100)
        IO.puts "Also Got #{el}"
      end
    end
    :timer.sleep(1000)
    GenEvent.notify(s, 0)
    GenEvent.notify(s, 1)
    GenEvent.notify(s, 2)
    GenEvent.notify(s, 3)
    GenEvent.notify(s, 4)
    GenEvent.notify(s, 5)
    GenEvent.notify(s, 6)
    :timer.sleep(1000)
  end
end
