defmodule Hosscoinbot.SlashCommands.Mint do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
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


    case mint_op(user.id, amount) do
      :unauthorized -> unauthorized_response()
      {:ok, minting} -> success_response(user, minting)
      {:error, msg} -> error_response(msg)
    end
  end

  defp mint_op(user_id, amount) when user_id in @allowed_minters, do: Operations.mint_coins(user_id, amount)
  defp mint_op(_, _), do: :unauthorized

  defp success_response(user, minting) do
    %{
      flags: 64, # Ephemeral
      content: "#{user.username} minted #{minting.amount} new $HOSS coins"
    }
  end

  defp error_response(msg) do
    %{
      flags: 64, # Ephemeral
      content: "Error minting coins: #{msg}"
    }
  end

  defp unauthorized_response() do
    %{
      flags: 64, # Ephemeral
      content: "Unauthorized minting detected, guards!"
    }
  end
end
