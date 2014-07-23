defmodule Streamz do
  @moduledoc """
  Module for creating and composing streams.

  Streamz is meant to complement the Stream module.
  """

  @doc """
  Creates a composite stream. The stream emits values from the underlying streams, in the
  order they are produced. This differs from `Stream.zip/2`, where the order of values is
  strictly alternating between the source streams.

    iex(1)> s1 = Stream.repeatedly fn ->
    ...(1)>   :timer.sleep(100)
    ...(1)>   :slow
    ...(1)> end
    #Function<18.77372642/2 in Stream.repeatedly/1>
    iex(2)> s2 = Stream.repeatedly fn ->
    ...(2)>   :timer.sleep(40)
    ...(2)>   :fast
    ...(2)> end
    #Function<18.77372642/2 in Stream.repeatedly/1>
    iex(3)> Streamz.merge([s1,s2]) |> Enum.take(3)
    [:fast, :fast, :slow]

  """
  @spec merge([Enumerable.t]) :: Enumerable.t
  def merge(streams) do
    Streamz.Merge.build_merge_stream(streams)
  end

  @doc """
  Takes elements from the first stream until the second stream produces data.
  """
  @spec take_until(Enumerable.t, Enumerable.t) :: Enumerable.t
  def take_until(stream, cutoff) do
    ref = make_ref
    wrapped_cutoff = cutoff |> Stream.map fn (_) ->
      ref
    end
    Streamz.merge([stream, wrapped_cutoff])
      |> Stream.take_while &( &1 != ref )
  end
end
