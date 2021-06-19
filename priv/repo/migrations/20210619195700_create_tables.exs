defmodule Hosscoinbot.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:mintings) do
      add :minter, :integer
      add :amount, :integer

      timestamps()
    end

    create table(:transactions) do
      add :from_id, :integer
      add :to_id, :integer, null: false
      add :amount, :integer
      add :minting_id, references(:mintings)

      timestamps()
    end
  end
end
