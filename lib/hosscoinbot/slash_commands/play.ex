defmodule Hosscoinbot.SlashCommands.Play do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.{Api, Voice}
  alias Hosscoinbot.Jukebox

  def command() do
    %{
      name: "play",
      description: "play track",
      options: [
        %{
          # ApplicationCommandType::STRING
          type: 3,
          name: "url",
          description: "youtube-dl url",
          required: true
        },
      ]
    }
  end

  def handle(interaction = %Interaction{data: %{
    options: [%{name: "url", type: 3, value: track_url}],
  }, guild_id: guild_id }) do
    {:ok, _pid} = Jukebox.ensure_started(guild_id)
    {:ok} = Api.create_interaction_response(interaction, loading_response())
    interaction_user_id = interaction.member.user.id
    if !Voice.playing?(guild_id) do
      :ok = Jukebox.ensure_bot_in_proper_voice_channel(guild_id, interaction_user_id)
    end

    response = case Jukebox.add_track(guild_id, track_url) do
      {:ok, playing_or_queued} -> ok_response(track_url, playing_or_queued)
      {:error, msg} -> error_response(msg, track_url)
    end

    {:ok, _msg} = Api.edit_interaction_response(interaction, response)
  end

  defp ok_response(track_url, :playing) do
    %{
      flags: 64, # Ephemeral
      content: "Playing track: #{track_url}"
    }
  end

  defp ok_response(track_url, {:queued, queue_length}) do
    %{
      flags: 64, # Ephemeral
      content: "Added track: #{track_url} to the queue. #{queue_length} song(s) now in the queue"
    }
  end

  defp error_response(msg, track_url) do
    %{
      flags: 64, # Ephemeral
      content: "Error #{msg} when playing track: #{track_url}"
    }
  end

  defp loading_response() do
    %{
      type: 5,
    }
  end
end
