defmodule Hosscoinbot.Model.Transaction do
  use Ecto.Schema

  schema "transactions" do
    field :from_id, :integer
    field :to_id, :integer
    field :amount, :integer
    belongs_to :minting, Hosscoinbot.Model.Minting

    timestamps()
  end
end
