defmodule Streamz do
  @moduledoc """
  Module for creating and composing streams.

  Streamz is meant to complement the Stream module.
  """

  alias Streamz.CompoundStream

  @doc """
  Creates a composite stream. The stream emits values from the underlying streams, in the
  order they are produced. This differs from `Stream.zip/2`, where the order of values is
  strictly alternating between the source streams.
  """
  @spec merge([Enumerable.t]) :: %CompoundStream{}
  def merge(streams) do
    %CompoundStream{streams: streams}
  end
end
