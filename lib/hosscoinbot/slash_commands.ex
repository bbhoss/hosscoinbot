defmodule Hosscoinbot.SlashCommands do
  require Logger
  alias Nostrum.Struct.{
    Interaction,
    Guild,
    ApplicationCommandInteractionData
  }

  defmodule SlashCommand do
    @type response() :: %{content: String.t(), flags: non_neg_integer()}
    defmacro __using__(_opts) do
      quote do
        @behaviour Hosscoinbot.SlashCommands.SlashCommand

        def init(_guild) do
          :noop
        end

        def message_component_ids, do: []

        defoverridable init: 1, message_component_ids: 0
      end
    end
    @callback init(Guild) :: any
    @callback command() :: map()
    @callback message_component_ids() :: [String.t()]
    @callback handle(Interaction.t) :: response()
    @callback handle_component(String.t, Interaction.t) :: response()

    @optional_callbacks handle_component: 2
  end

  @commands [
    Hosscoinbot.SlashCommands.Balance,
    Hosscoinbot.SlashCommands.Mint,
    Hosscoinbot.SlashCommands.Transfer,
    Hosscoinbot.SlashCommands.Log,
    Hosscoinbot.SlashCommands.Hoarders,
    Hosscoinbot.SlashCommands.Play,
    Hosscoinbot.SlashCommands.Skip,
    Hosscoinbot.SlashCommands.NowPlaying,
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
    def handle_interaction(interaction = %Interaction{type: 2, data: %{name: unquote(interaction_name) }}) do
      unquote(command_mod).handle(interaction)
    end

    for message_component_id <- command_mod.message_component_ids do
      def handle_interaction(interaction = %Interaction{type: 3, data: %ApplicationCommandInteractionData{custom_id: unquote(message_component_id) }}) do
        unquote(command_mod).handle_component(interaction.data.custom_id, interaction)
      end
    end
  end

  def handle_interaction(interaction) do
    Logger.debug("Catch all handler for interactions caught #{inspect(interaction)}")
    :ignore
  end

  def init(guild) do
    for command <- @commands, do: command.init(guild)
  end
end
