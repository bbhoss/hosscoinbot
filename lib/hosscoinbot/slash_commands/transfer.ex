defmodule Hosscoinbot.SlashCommands.Transfer do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Hosscoinbot.Operations

  def command() do
    %{
      name: "transfer",
      description: "transfer some of your $HOSS coin to another account",
      options: [
        %{
          type: 6,
          name: "receiver",
          description: "who you're sending coin to",
          required: true
        },
        %{
          type: 4,
          name: "amount",
          description: "amount of coin",
          required: true
        },
      ]
    }
  end

  def handle(interaction = %Interaction{data: %{
    options: [
      %{name: "receiver", type: 6, value: receiver_id},
      %{name: "amount", type: 4, value: amount}
    ]
  }}) do
    receiver = interaction.data.resolved.users[receiver_id]
    user = interaction.member.user
    case Operations.transfer(user.id, receiver.id, amount) do
      {:ok, txn} -> success_response(user, receiver, txn)
      {:error, msg} -> error_response(msg)
    end
  end

  defp success_response(user, receiver, txn) do
    %{
      flags: 64, # Ephemeral
      content: "#{user.username} transferred #{txn.amount} $HOSS coins to #{receiver.username}"
    }
  end

  defp error_response(msg) do
    %{
      flags: 64, # Ephemeral
      content: "Error transferring coins: #{msg}"
    }
  end
end
