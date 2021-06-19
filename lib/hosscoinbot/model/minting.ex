defmodule Hosscoinbot.Model.Minting do
  use Ecto.Schema

  schema "mintings" do
    field :minter, :integer
    field :amount, :integer
    has_one :transaction, Hosscoinbot.Model.Transaction

    timestamps()
  end
end
