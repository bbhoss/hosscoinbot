defmodule Hosscoinbot.SlashCommands do
  require Logger
  alias Nostrum.Struct.Interaction
  defmodule SlashCommand do
    @callback command() :: map()
    @callback handle(Interaction.t) :: any
  end

  @commands [
    Hosscoinbot.SlashCommands.Balance,
    Hosscoinbot.SlashCommands.Mint,
    Hosscoinbot.SlashCommands.Transfer,
    Hosscoinbot.SlashCommands.Log,
  ]
  @all_commands_with_names Enum.map(@commands, &({&1, &1.command[:name]}))

  def all_commands(), do: @commands

  @spec install(non_neg_integer, atom) ::
          {:error, String.t} | {:ok, map}
  def install(guild_id, command_module) do
    case Nostrum.Api.create_guild_application_command(guild_id, command_module.command) do
      {:ok, command} -> {:ok, command}
      {:error, _err} -> {:error, "Error installing command #{inspect(command_module)}"}
    end
  end

  for {command_mod, interaction_name} <- @all_commands_with_names do
    def handle_interaction(interaction = %Interaction{data: %{name: unquote(interaction_name) }}) do
      unquote(command_mod).handle(interaction)
    end
  end

  def handle_interaction(interaction) do
    Logger.debug("Catch all handler for interactions caught #{inspect(interaction)}")
    :ignore
  end
end
