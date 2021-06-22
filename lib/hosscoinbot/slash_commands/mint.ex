defmodule Hosscoinbot.SlashCommands.Mint do
  @behaviour Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.Api
  alias Hosscoinbot.Operations

  @allowed_minters [
    190221514245668864
  ]

  def command() do
    %{
      name: "mint",
      description: "create new $HOSS coins (minters only, sorry!)",
      options: [
        %{
          # ApplicationCommandType::INTEGER
          type: 4,
          name: "amount",
          description: "amount of coins to mint",
          required: true
        },
      ]
    }
  end

  def handle(interaction = %Interaction{data: %{
    options: [%{name: "amount", type: 4, value: amount}]
  }}) do
    user = interaction.member.user


    response = case mint_op(user.id, amount) do
      :unauthorized -> unauthorized_response()
      {:ok, minting} -> success_response(user, minting)
      {:error, msg} -> error_response(msg)
    end

    Api.create_interaction_response(interaction, response)
  end

  defp mint_op(user_id, amount) when user_id in @allowed_minters, do: Operations.mint_coins(user_id, amount)
  defp mint_op(_, _), do: :unauthorized

  defp success_response(user, minting) do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "#{user.username} minted #{minting.amount} new $HOSS coins"
      }
    }
  end

  defp error_response(msg) do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "Error minting coins: #{msg}"
      }
    }
  end

  defp unauthorized_response() do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "Unauthorized minting detected, guards!"
      }
    }
  end
end
