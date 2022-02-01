defmodule Hosscoinbot.SlashCommands.Log do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.Api
  alias Hosscoinbot.Operations
  alias Hosscoinbot.Model.Transaction

  def command() do
    %{
      name: "log",
      description: "get a transaction log",
      options: [
        %{
          # ApplicationCommandType::USER
          type: 6,
          name: "user",
          description: "the user you want to see the transactions for",
          required: false
        },
      ]
    }
  end

  def handle(interaction = %Interaction{data: %{
    options: [%{name: "user", type: 6, value: user_id}]
  }}) do
    user = interaction.data.resolved.users[user_id]
    txns = Operations.user_transactions(user.id)

    Api.create_interaction_response(interaction, response(user, txns))
  end

  def handle(interaction = %Interaction{}) do
    user = interaction.member.user
    txns = Operations.user_transactions(user.id)

    Api.create_interaction_response(interaction, response(user, txns))
  end

  defp response(user, txns) do
    logs_message =
      Enum.map(txns, fn
        %Transaction{from_id: nil, minting_id: minting_id, amount: amount} when is_integer(minting_id) -> "Minted: #{amount}"
        txn = %Transaction{} -> "From: #{txn.from_id} To: #{txn.to_id} Amount: #{txn.amount}"
      end)
      |> Enum.join("\n")

    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "#{user.username}'s Transactions:\n#{logs_message}"
      }
    }
  end
end
