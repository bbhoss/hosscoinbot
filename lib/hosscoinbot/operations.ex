defmodule Hosscoinbot.Operations do
  require Logger
  import Ecto.Query
  alias Ecto.Multi
  alias Hosscoinbot.Repo
  alias Hosscoinbot.Model.{Minting, Transaction}

  @spec mint_coins(Integer.t, Integer.t) :: {:ok, Minting.t} | {:error, String.t}
  def mint_coins(user_id, amount) do
    multi_op = Multi.new()
      |> Multi.insert(:minting, %Minting{minter: user_id, amount: amount})
      |> Multi.insert(:txn, fn %{minting: minting} ->
        txn = Ecto.build_assoc(minting, :transaction)
        %Transaction{txn | to_id: user_id, amount: amount}
      end)
      |> Repo.transaction()

    case multi_op do
      {:ok, changes} -> {:ok, Map.get(changes, :minting)}
      {:error, _, _, _} -> {:error, "Error minting coins"}
    end
  end

  @spec balance(Integer.t) :: Integer.t
  def balance(user_id) do
    sent_to_user = from t in Transaction, where: t.to_id == ^user_id, select: sum(t.amount)
    sent_from_user = from t in Transaction, where: t.from_id == ^user_id, select: sum(t.amount)
    (Repo.one(sent_to_user) || 0) - (Repo.one(sent_from_user) || 0)
  end

  @spec transfer(Integer.t, Integer.t, Integer.t) :: {:ok, Transaction.t} | {:error, String.t}
  def transfer(from_user_id, to_user_id, amount) do
    current_balance = balance(from_user_id)

    case current_balance do
      cbal when cbal >= amount ->
        case Repo.insert(%Transaction{from_id: from_user_id, to_id: to_user_id, amount: amount}) do
          {:ok, txn} -> {:ok, txn}
          {:error, err} ->
            Logger.error("Couldn't persist transaction #{err}")
            {:error, "Could not persist transaction"}
        end
      cbal when cbal < amount ->
        {:error, "Insufficient balance, sender only has #{cbal} $HOSS, and tried to send #{amount} $HOSS"}
    end
  end

  @spec user_transactions(Integer.t) :: [Transaction.t]
  def user_transactions(user_id) do
    Repo.all(from t in Transaction, where: t.to_id == ^user_id or t.from_id == ^user_id)
  end
end
