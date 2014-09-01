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
  @spec merge(Enumerable.t) :: Enumerable.t
  def merge(streams) do
    Streamz.Merge.new(streams)
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

  @doc """
  Takes two streams and creates a combined stream of form {left, right} using the most recent
  elements emitted by the two input streams. No elements are emitted from the returned stream
  until both input streams have emitted elements.
  """
  @spec combine_latest(Enumerable.t, Enumerable.t) :: Enumerable.t
  def combine_latest(stream1, stream2) do
    left = Stream.map(stream1, &({:left, &1}))
    right = Stream.map(stream2, &({:right, &1}))
    Streamz.merge([left, right])
    |> Stream.scan({nil,nil}, fn(el, {left, right}) ->
      case el do
        {:left,_} -> {el,right}
        {:right,_} -> {left,el}
      end
    end)
    |> Stream.drop_while(fn {a,b} -> a == nil or b == nil end)
    |> Stream.map(fn {{_,a},{_,b}} -> {a,b} end)
  end
  
  @doc """
  Creates a stream that emits one element.
  
  The element is the result of executing the passed in function.

    iex(1)> Streamz.once(fn -> "foo" end) |> Enum.take(2)
    ["foo"]

  """
  @spec once(fun) :: Enumerable.t
  def once(fun) do
    Stream.unfold true, fn
      (true) -> {fun.(), false}
      (false) -> nil
    end
  end

  @doc """
  Take `n` elements and pass them into the given function before continuing to enumerate the stream.

  iex(1)> 1..100 |> Streamz.take_and_continue(5, &IO.inspect/1) |> Enum.take(10)
  [1, 2, 3, 4, 5]
  [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  """
  @spec take_and_continue(Enumerable.t, non_neg_integer, (Enumerable.t -> term)) :: Enumerable.t
  def take_and_continue(stream, count, fun) do
    stream |> Stream.transform [], fn
      (el, acc) when is_list(acc) and length(acc) == count ->
        fun.(Enum.reverse(acc))
        {[el], nil}
      (el, nil) ->
        {[el], nil}
      (el, acc) ->
        {[], [el | acc]}
    end
  end

  @doc """
  Remove repeated elements.

  iex(1)> Streamz.dedupe([1,1,2,3,2,3,4,5,5])
  [1,2,3,2,3,4,5]
  """
  @spec dedupe(Enumerable.t) :: Enumerable.t
  def dedupe(stream) do
    stream |> Stream.transform nil, fn
      (last, last) -> {[], last}
      (el, _) -> {[el], el}
    end
  end

  @doc """
  Spawn `n` processes, one for each element, apply `fun` to each fo them and collect the results.

  Does not preserve order. If order is important, the recommended approach is to tag the elements
  with the index and then sort.

  iex(1)> Streamz.pmap(1..5, &(&1 * 2)) |> Enum.to_list
  [2,6,4,8,10]

  iex(1)> Stream.with_index(1..5))
  ...(1)>  |> Streamz.pmap(fn ({el, i}) -> {el * 2, i} end)
  ...(1)>  |> Enum.sort_by( &elem(&1,1) )
  ...(1)>  |> Enum.map( &elem(&1, 0) )
  [2,4,6,8,10]
  """
  def pmap(stream, fun) do
    stream
      |> Stream.map(fn (el) ->
        Streamz.once(fn -> fun.(el) end)
      end)
      |> Streamz.merge
  end
end
