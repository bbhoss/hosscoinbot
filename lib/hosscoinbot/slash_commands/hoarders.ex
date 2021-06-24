defmodule Hosscoinbot.SlashCommands.Hoarders do
  @behaviour Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.Api
  alias Hosscoinbot.Operations

  def command() do
    %{
      name: "hoarders",
      description: "list top 10 holders of $HOSS coin",
      options: []
    }
  end

  def handle(interaction = %Interaction{}) do
    hoarders_balances = Operations.hoarders(10)
    hoarders_with_users = for [user_id, balance] <- hoarders_balances, do: {Api.get_user!(user_id), balance}

    Api.create_interaction_response(interaction, response(hoarders_with_users))
  end

  defp response(hoarders_balances) do
    hoarders_balances_string = for {hoarder, balance} <- hoarders_balances, do: "#{hoarder.username}: #{balance}\n", into: ""
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "Top 10 $HOSS coin hoarders:\n#{hoarders_balances_string}"
      }
    }
  end
end
