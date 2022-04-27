defmodule Lilac.Repo.Migrations.AddUserTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :discord_id, :string
      add :username, :string
      add :last_indexed, :naive_datetime_usec
      add :last_fm_session, :string, null: true
      add :privacy, :integer

      timestamps()
    end
  end
end