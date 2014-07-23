defmodule Streamz.Time do
  @moduledoc """
  Create streams based on time.
  """

  @doc """
  Emit `:ok` every `length` milliseconds.
  """
  @spec interval(integer) :: Enumerable.t
  def interval(length) do
    Stream.repeatedly fn ->
      :timer.sleep(length)
    end
  end

  @doc """
  Emit a single `:ok` after `length` milliseconds.
  """
  @spec timer(integer) :: Enumerable.t
  def timer(length) do
    interval(length) |> Stream.take(1)
  end
end
