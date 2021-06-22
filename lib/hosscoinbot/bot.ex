defmodule Hosscoinbot.Bot do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [Hosscoinbot.TreasuryConsumer]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Hosscoinbot.TreasuryConsumer do
  use Nostrum.Consumer
  require Logger

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias Hosscoinbot.{Operations, SlashCommands}

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:INTERACTION_CREATE, %Interaction{} = interaction, _ws_state}) do
    Logger.debug("Interaction created event:\n#{inspect(interaction)}")
    SlashCommands.handle_interaction(interaction)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case String.downcase(msg.content) do
      "$install" ->
        case Operations.install_slash_commands(msg.guild_id) do
          :ok -> Api.create_message(msg.channel_id, "Slash commands installed!")
          {:error, msgs} -> Api.create_message(msg.channel_id, "Error installing slash commands:\n#{msgs}")
        end
      "$help" ->
        Api.create_message(msg.channel_id, """
          Hosscoinbot now uses Slash Commands for input. To install the commands send `$install`,
          then hit / in the chat box to see the various commands.
        """)
      _ ->
        :ignore
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end
