defmodule Hosscoinbot.SlashCommands.Skip do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Hosscoinbot.Jukebox

  def command() do
    %{
      name: "skip",
      description: "skip currently playing track",
      options: []
    }
  end

  def handle(%Interaction{guild_id: guild_id }) do
    {:ok, _pid} = Jukebox.ensure_started(guild_id)
    case Jukebox.skip_track(guild_id) do
      :ok -> ok_response()
      :not_playing -> not_playing_response()
    end
  end

  defp ok_response() do
    %{
      flags: 64, # Ephemeral
      content: "Skipped currently playing track"
    }
  end

  defp not_playing_response() do
    %{
      flags: 64, # Ephemeral
      content: "No track playing to skip"
    }
  end
end
