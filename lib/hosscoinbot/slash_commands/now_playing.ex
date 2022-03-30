defmodule Hosscoinbot.SlashCommands.NowPlaying do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Hosscoinbot.Jukebox

  def command() do
    %{
      name: "now_playing",
      description: "Print the currently playing track",
      options: []
    }
  end

  def handle(%Interaction{guild_id: guild_id }) do
    {:ok, _pid} = Jukebox.ensure_started(guild_id)
    case Jukebox.now_playing(guild_id) do
      %URI{} = uri -> ok_response(uri)
      :not_playing -> not_playing_response()
    end
  end

  defp ok_response(uri) do
    %{
      flags: 64, # Ephemeral
      content: "Currently Playing: #{uri}"
    }
  end

  defp not_playing_response() do
    %{
      flags: 64, # Ephemeral
      content: "No track currently playing"
    }
  end
end
