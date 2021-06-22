defmodule Hosscoinbot.SlashCommands.Balance do
  @behaviour Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.Api
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
    user_id_a = String.to_existing_atom(user_id)
    user = interaction.data.resolved.users[user_id_a]
    balance = Operations.balance(user.id)

    Api.create_interaction_response(interaction, response(user, balance))
  end

  def handle(interaction = %Interaction{}) do
    user = interaction.member.user
    balance = Operations.balance(user.id)


    Api.create_interaction_response(interaction, response(user, balance))
  end

  defp response(user, balance) do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "#{user.username}'s Balance: #{balance}"
      }
    }
  end
end
