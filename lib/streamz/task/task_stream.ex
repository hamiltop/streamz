defmodule Streamz.Task.TaskStream do
  @moduledoc false

  defstruct pid: nil

  @spec start_link(Enumerable.t) :: %__MODULE__{}
  def start_link(funs) do
    {:ok, sup} = Task.Supervisor.start_link()

    pid = spawn_link fn ->
      task_refs = launch_tasks(sup, funs)
                  |> Enum.map(fn(task) -> task.ref end)
                  |> Enum.into HashSet.new

      wait_for_request(task_refs)
      
    end
    %__MODULE__{pid: pid}
  end

  @spec launch_tasks(atom, Enumerable.t) :: Enumerable.t
  defp launch_tasks(pid, funs), do: Enum.map(funs, fn(fun) -> Task.Supervisor.async(pid, fun) end)

  @spec wait_for_request(Enumerable.t) :: term
  defp wait_for_request(refs) do
    receive do
      {:get, pid} -> wait_for_results(pid, refs)
    end
  end

  @spec wait_for_results(pid, Enumerable.t) :: term
  defp wait_for_results(parent, refs) do
    if Enum.count(refs) > 0 do
      # only looking for responses... dropping everything else
      receive do
        {ref, value} ->
          send parent, {self, value}
          wait_for_request(HashSet.delete(refs, ref)) 
      end
    else
      send parent, {:done, self}
    end
  end
end

defimpl Enumerable, for: Streamz.Task.TaskStream do
  def count(_), do: {:error, __MODULE__}
  def member?(_,_), do: {:error, __MODULE__}

  def reduce(stream, acc, reducer) do
    Stream.unfold(stream.pid, fn(pid) ->
      send pid, {:get, self}
      receive do
        {^pid, value} -> {value, pid}
        {:done, ^pid} -> nil
      end
    end).(acc, reducer)
  end
end
