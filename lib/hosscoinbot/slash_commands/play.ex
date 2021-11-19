defmodule Hosscoinbot.SlashCommands.Play do
  @behaviour Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.Api
  alias Nostrum.Voice

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
    channel = Application.fetch_env!(:hosscoinbot, :play_channel_id)
    :ok = Voice.join_channel(guild_id, channel)
    :timer.sleep(2000) # Sleep for async join
    Voice.stop(guild_id)
    response = case Voice.play(guild_id, track_url, :ytdl, realtime: true) do
      :ok -> ok_response(track_url)
      {:error, msg} -> error_response(msg, track_url)
    end

    Api.create_interaction_response(interaction, response)
  end

  defp ok_response(track_url) do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "Playing track: #{track_url}"
      }
    }
  end

  defp error_response(msg, track_url) do
    %{
      type: 4,
      flags: 64, # Ephemeral
      data: %{
        content: "Error #{msg} when playing track: #{track_url}"
      }
    }
  end
end
