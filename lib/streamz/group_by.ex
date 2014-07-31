defmodule GroupBy do
  defstruct config: nil, consumer: nil
  def launch(stream, fun) do
    {:ok, config} = GroupedStreamConfig.start_link
    {:ok, consumer} = StreamConsumer.start_link(stream, fun, config)
    %__MODULE__{config: config, consumer: consumer}
  end

  def create_substream(stream, key) do
    Stream.resource(
      fn -> start(stream, key) end,
      &next(&1),
      &stop(&1)
    )
  end

  def start(stream, key) do
    {:ok, pid} = GroupedStream.start_link(stream, key) 
    pid
  end

  def next(pid) do
    {GroupedStream.next(pid), pid}
  end

  def stop(pid) do
  end
end

defimpl Access, for: GroupBy do
  def get(stream, key) do
    GroupBy.create_substream(stream, key)      
  end
  def get_and_update(_, _, _) do
    raise :update_not_supported
  end 
end
