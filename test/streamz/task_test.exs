defmodule TaskTest do
  use ExUnit.Case

  test "stream - tasks should all execute" do
    stream = Streamz.Task.stream [
      fn -> 1 end, 
      fn -> 2 end, 
      fn -> 3 end, 
      fn -> 4 end
    ]
    results = stream |> Enum.sort
    assert results == [1,2,3,4]
  end

  test "stream - tasks should return in the order of completion" do
    stream = Streamz.Task.stream [
      fn ->
        :timer.sleep(10)
        1
      end, 
      fn -> 2 end
    ]
    result = stream |> Enum.to_list
    assert result == [2,1]
  end

  test "Stream - TaskStream pid should ignore stray messages" do
    stream = Streamz.Task.stream [
      fn ->
        :timer.sleep(100)
        1
      end, 
      fn -> 2 end
    ]
    task = Task.async fn ->
      stream |> Enum.to_list
    end
    #send stream.pid, {:hi, 12}
    result = Task.await(task)
    assert result == [2,1]
  end

  test "first_completed_of - should return value of first completed function" do
    value = Streamz.Task.first_completed_of [
      fn ->
        :timer.sleep(100)
        1
      end, 
      fn -> 2 end
    ]
    assert value == 2
  end
end
