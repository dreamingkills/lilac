defmodule Lilac.IndexerRegistry do
  @moduledoc """
  Maps user ids to IndexingSupervisor processes
  """

  def process_name(user, process) do
    {:via, Registry, {Lilac.IndexerRegistry, process.(user)}}
  end

  def get_pid(user, process) do
    Registry.lookup(Lilac.IndexerRegistry, process.(user))
    |> Enum.at(0)
    |> case do
      {pid, nil} -> pid
      nil -> nil
    end
  end

  def indexing_supervisor_name(user), do: via_tuple("supervisor-#{user.id}")
  def indexing_server_name(user), do: via_tuple("indexing-#{user.id}")
  def counting_server_name(user), do: via_tuple("counting-#{user.id}")
  def converting_server_name(user), do: via_tuple("converting-#{user.id}")
  def indexing_progress_server_name(user), do: via_tuple("indexing-progress-#{user.id}")

  defp via_tuple(name), do: {:via, Registry, {Lilac.IndexerRegistry, name}}
end