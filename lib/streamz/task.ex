defmodule Streamz.Task do
  @moduledoc """
  Conveniences for spawning and awaiting for tasks.

  Streamz.Task is meant to complement the Task module.
  """

  @doc """
  Creates a stream of results of multiple functions.

  Every function will execute in parallel. The results will be streamed in the order
  that execution completed.
  """
  @spec stream(Enumerable.t) :: %Streamz.Task.TaskStream{}
  def stream(funs) do
    Streamz.Task.TaskStream.start_link(funs)
  end

  @doc """
  Return the result of the first function to complete.

  Executes multiple functions in parallel and returns the value of the first one that completes
  execution.
  """
  @spec first_completed_of(Enumerable.t) :: term
  def first_completed_of(funs) do
    stream(funs)
      |> Enum.take(1)
      |> hd
  end
end
