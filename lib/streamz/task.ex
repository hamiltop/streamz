defmodule Streamz.Task do

  @spec stream(Enumerable.t) :: Enumerable.t
  def stream(funs) do
    Stream.map(funs, fn(fun) ->
      Streamz.once(fun)
    end) |> Streamz.merge
  end

  def first_completed_of(funs) do
    stream(funs) |> Enum.take(1) |> hd
  end
end
