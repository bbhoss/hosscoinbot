defmodule Hosscoinbot.SlashCommands.Play do
  use Hosscoinbot.SlashCommands.SlashCommand
  alias Nostrum.Struct.Interaction
  alias Nostrum.Voice
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

  def message_component_ids(), do: ["replay"]

  def handle(interaction = %Interaction{data: %{
    options: [%{name: "url", type: 3, value: track_url}],
  }, guild_id: guild_id }) do
    play_url(guild_id, interaction_user_id(interaction), track_url)
  end

  def handle_component("replay", interaction) do
    play_url(interaction.guild_id, interaction_user_id(interaction), extract_url(interaction))
  end

  defp play_url(guild_id, interaction_user_id, track_url) do
    {:ok, _pid} = Jukebox.ensure_started(guild_id)

    if !Voice.playing?(guild_id) do
      :ok = Jukebox.ensure_bot_in_proper_voice_channel(guild_id, interaction_user_id)
    end

    case Jukebox.add_track(guild_id, track_url) do
      {:ok, playing_or_queued} -> ok_response(track_url, playing_or_queued)
      {:error, msg} -> error_response(msg, track_url)
    end
  end

  defp extract_url(interaction) do
    [_, url] = Regex.run(~r/^Playing track: (http.+)$/m, interaction.message.content)
    url
  end

  defp interaction_user_id(interaction), do: interaction.member.user.id

  defp ok_response(track_url, :playing) do
    %{
      flags: 0,
      content: "Playing track: #{track_url}",
      components: ok_components()
    }
  end

  defp ok_response(track_url, {:queued, queue_length}) do
    %{
      flags: 0,
      content: "Playing track: #{track_url}\n\n#{queue_length} song(s) now in the queue",
      components: ok_components()
    }
  end

  defp error_response(msg, track_url) do
    %{
      flags: 0,
      content: "Error #{msg} when playing track: #{track_url}"
    }
  end

  defp ok_components do
    [
      %{
        type: 1,
        components: [
          %{
              type: 2,
              label: "Replay",
              style: 1,
              custom_id: "replay"
          }
        ]
      }
    ]
  end
end
