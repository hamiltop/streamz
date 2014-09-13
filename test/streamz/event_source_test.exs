defmodule EventSourceTest do
  use ExUnit.Case

  test "works with GenEvent as target" do
    {:ok, g} = GenEvent.start_link
    {:ok, a} = Agent.start_link fn -> [] end

    spawn_link fn ->
      GenEvent.stream(g) |> Enum.each fn (el) ->
        Agent.update a, fn (acc) -> [el | acc] end
      end
    end

    source = ["foo", "bar", "qux"]
    EventSource.add_handler(source, g)
    :timer.sleep(100)
    assert Agent.get(a, &Enum.reverse/1) == source
  end

  test "works with GenEvent as target with infinite streams" do
    {:ok, g} = GenEvent.start_link
    {:ok, a} = Agent.start_link fn -> [] end

    spawn_link fn ->
      GenEvent.stream(g) |> Enum.each fn (el) ->
        Agent.update a, fn (acc) -> [el | acc] end
      end
    end

    source = Stream.cycle(["foo", "bar", "qux"])
    p = EventSource.add_handler(source, g)
    :timer.sleep(200)
    Enum.each p, fn (conn) ->
      EventSource.remove_handler(source, conn)
    end
    :timer.sleep(10)
    assert Enum.take(Agent.get(a, &Enum.reverse/1), 3) == Enum.take(source, 3)
    Enum.each p, fn (conn) ->
      refute Process.alive?(conn.pid)
    end
  end

  Enum.each [:ack, :sync, :async], fn (mode) ->
    test "works with GenEvent as source in mode #{inspect mode}" do
      {:ok, g} = GenEvent.start_link
      {:ok, h} = GenEvent.start_link
      {:ok, a} = Agent.start_link fn -> [] end

      spawn_link fn ->
        GenEvent.stream(g) |> Enum.each fn (el) ->
          Agent.update a, fn (acc) -> [el | acc] end
        end
      end

      source = ["foo", "bar", "qux"]
      EventSource.add_handler(GenEvent.stream(h), g)

      case unquote(mode) do
        :ack   -> Enum.each(source, &GenEvent.ack_notify(h,&1))
        :sync  -> Enum.each(source, &GenEvent.sync_notify(h,&1))
        :async -> Enum.each(source, &GenEvent.notify(h,&1))
      end
      :timer.sleep(200)
      assert Agent.get(a, &Enum.reverse/1) == source
    end
  end

end
