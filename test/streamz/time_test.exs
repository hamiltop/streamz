defmodule TimeTest do
  use ExUnit.Case

  test "interval" do
    stream = Streamz.Time.interval(50)
    task = Task.async fn ->
      stream |> Enum.take(5)
    end
    result = Task.await(task, 300)
    assert result == [:ok, :ok, :ok, :ok, :ok]
  end

  test "timer" do
    stream = Streamz.Time.timer(50)
    task = Task.async fn ->
      stream |> Enum.to_list
    end
    result = Task.await(task, 150)
    assert result = [:ok]
  end
end
