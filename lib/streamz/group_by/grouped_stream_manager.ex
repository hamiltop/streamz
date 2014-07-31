defmodule GroupedStreamManager do
  defstruct config: nil, consumer: nil
  def launch(stream, fun) do
    {:ok, config} = GroupedStreamConfig.start_link
    {:ok, consumer} = StreamConsumer.start_link(stream, fun, config)
    %__MODULE__{config: config, consumer: consumer}
  end
end
