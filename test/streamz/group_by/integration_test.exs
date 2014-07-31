defmodule GroupedIntegrationTest do
  use ExUnit.Case

  test "do it" do
    stream = [1,2,3,4,5]
    {:ok, config } = GroupedStreamConfig.start_link
    {:ok, consumer} = StreamConsumer.start_link(stream, fn(el) -> rem(el, 3) end, config)
    {:ok, grouped} = GroupedStream.start_link(consumer, config, 1)
    {:ok, grouped2} = GroupedStream.start_link(consumer, config, 2)
    assert [
      GroupedStream.next(grouped),
      GroupedStream.next(grouped),
      GroupedStream.next(grouped2),
      GroupedStream.next(grouped2)
    ] == [1,3,2,4]
  end
end
