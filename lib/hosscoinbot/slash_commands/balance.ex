defmodule Hosscoinbot.SlashCommands.Balance do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Hosscoinbot.Operations

  def command() do
    %{
      name: "balance",
      description: "check balance of yourself or another user",
      options: [
        %{
          # ApplicationCommandType::USER
          type: 6,
          name: "user",
          description: "role to assign or remove",
          required: false
        },
      ]
    }
  end

  def handle(interaction = %Interaction{data: %{
    options: [%{name: "user", type: 6, value: user_id}]
  }}) do
    user = interaction.data.resolved.users[user_id]
    balance = Operations.balance(user.id)

    response(user, balance)
  end

  def handle(interaction = %Interaction{}) do
    user = interaction.member.user
    balance = Operations.balance(user.id)


    response(user, balance)
  end

  defp response(user, balance) do
    %{
      flags: 64, # Ephemeral
      content: "#{user.username}'s Balance: #{balance}"
    }
  end
end
