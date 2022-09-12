defmodule Lilac.Servers.Indexing do
  use GenServer, restart: :permanent

  alias Lilac.Servers.Concurrency

  # Client api

  @spec index_user(pid | atom, Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def index_user(pid, user) do
    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:index, user})
        {:ok, nil}

      error ->
        error
    end
  end

  @spec update_user(pid | atom, Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def update_user(pid, user) do
    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:update, user})
        {:ok, nil}

      error ->
        error
    end
  end

  @spec handle_concurrency(integer) :: {:ok, nil} | {:error, String.t()}
  defp handle_concurrency(user_id) do
    user_doing_action = Concurrency.is_doing_action?(ConcurrencyServer, :indexing, user_id)

    if !user_doing_action do
      Concurrency.register(ConcurrencyServer, :indexing, user_id)
      {:ok, nil}
    else
      {:error, "User is already being indexed or updated!"}
    end
  end

  # Server callbacks

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  @spec handle_cast({:index, Lilac.User.t()}, term) :: {:noreply, nil}
  def handle_cast({:index, user}, _state) do
    pids = start_servers(:indexing, user)

    Lilac.Indexing.index(pids, user)

    {:noreply, nil}
  end

  @impl true
  @spec handle_cast({:update, Lilac.User.t()}, term) :: {:noreply, nil}
  def handle_cast({:update, user}, _state) do
    pids = start_servers(:updating, user)

    Lilac.Indexing.update(pids, user)

    {:noreply, nil}
  end

  @spec stop_servers(Lilac.User.t()) :: no_return
  def stop_servers(user) do
    Supervisor.terminate_child(ConvertingSupervisor, "#{user.id}-converting")
    Supervisor.terminate_child(ConvertingSupervisor, "#{user.id}-indexing-progress")
  end

  @spec start_servers(:indexing | :updating, Lilac.User.t()) :: %{
          converting: pid,
          indexing_progress: pid
        }
  defp start_servers(action, user) do
    converting_pid =
      case Supervisor.restart_child(ConvertingSupervisor, "#{user.id}-converting") do
        {:ok, pid} ->
          pid

        {:error, :not_found} ->
          {:ok, converting_pid} =
            Supervisor.start_child(
              ConvertingSupervisor,
              create_converting_child_spec(user)
            )

          converting_pid
      end

    indexing_progress_pid =
      case Supervisor.restart_child(ConvertingSupervisor, "#{user.id}-indexing-progress") do
        {:ok, pid} ->
          pid

        {:error, :not_found} ->
          {:ok, indexing_progress_pid} =
            Supervisor.start_child(
              ConvertingSupervisor,
              create_indexing_progress_child_spec(action, user)
            )

          indexing_progress_pid
      end

    %{converting: converting_pid, indexing_progress: indexing_progress_pid}
  end

  @spec create_converting_child_spec(Lilac.User.t()) ::
          :supervisor.child_spec()
  defp create_converting_child_spec(user) do
    Supervisor.child_spec({Lilac.Servers.Converting, %{}}, id: "#{user.id}-converting")
  end

  @spec create_indexing_progress_child_spec(:indexing | :updating, Lilac.User.t()) ::
          :supervisor.child_spec()
  defp create_indexing_progress_child_spec(action, user) do
    Supervisor.child_spec({Lilac.Servers.IndexingProgress, action},
      id: "#{user.id}-indexing-progress"
    )
  end
end
