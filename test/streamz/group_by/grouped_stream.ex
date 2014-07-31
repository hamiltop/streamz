defmodule GroupedStreamTest do
  use ExUnit.Case

  test "requesting data when no data has been received" do
    expected_value = "foo"
    pid = spawn_link fn ->
      target = receive do
        {:target, pid} -> pid
      end
      receive do
        {:next, "test"} ->
          send target, {:data, expected_value}
      end
    end
    {:ok, grouped_stream} = GroupedStream.start_link pid, "test"
    send pid, {:target, grouped_stream}
    value = GroupedStream.next(grouped_stream)
    assert value == expected_value
  end

  test "requesting data when data has already been received" do
    expected_value = "bar"
    other_value = "foo"
    pid = spawn_link fn ->
      target = receive do
        {:target, pid} -> pid
      end
      receive do
        {:next, "test"} ->
          send target, {:data, other_value}
      end
    end
    {:ok, grouped_stream} = GroupedStream.start_link pid, "test"
    send grouped_stream, {:data, expected_value}
    send pid, {:target, grouped_stream}
    value = GroupedStream.next(grouped_stream)
    assert value == expected_value
  end

  test "requesting data when double data is received" do
    expected_value = "bar"
    other_value = "foo"
    pid = spawn_link fn ->
      target = receive do
        {:target, pid} -> pid
      end
      receive do
        {:next, "test"} ->
          send target, {:data, expected_value}
          send target, {:data, other_value}
      end
    end
    {:ok, grouped_stream} = GroupedStream.start_link pid, "test"
    send pid, {:target, grouped_stream}
    value = GroupedStream.next(grouped_stream)
    assert value == expected_value
    value = GroupedStream.next(grouped_stream)
    assert value == other_value
  end
end
