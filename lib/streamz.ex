defmodule Streamz do
  def merge(streams) do
    %CompoundStream{streams: streams}
  end
end
