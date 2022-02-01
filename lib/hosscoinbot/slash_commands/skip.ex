defmodule Hosscoinbot.SlashCommands.Skip do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.Api
  alias Hosscoinbot.Jukebox

  def command() do
    %{
      name: "skip",
      description: "skip currently playing track",
      options: []
    }
  end

  def handle(interaction = %Interaction{guild_id: guild_id }) do
    {:ok, _pid} = Jukebox.ensure_started(guild_id)
    response = case Jukebox.skip_track(guild_id) do
      :ok -> ok_response()
      :not_playing -> not_playing_response()
    end

    Api.create_interaction_response(interaction, response)
  end

  defp ok_response() do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "Skipped currently playing track"
      }
    }
  end

  defp not_playing_response() do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "No track playing to skip"
      }
    }
  end
end
