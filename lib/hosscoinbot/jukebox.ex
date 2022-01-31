defmodule Hosscoinbot.Jukebox do
  require Logger
  use GenServer
  alias Nostrum.Voice

  defmodule State do
    defstruct queue: :queue.new(), guild_id: nil, currently_playing: :not_playing, player_monitor_ref: nil
  end

  def ensure_started(guild_id) do
    case start(guild_id) do
      {:ok, pid} -> {:ok, pid}
      :ignore    ->
        {:ok, guild_jukebox(guild_id)}
    end
  end

  def start(guild_id) do
    GenServer.start(__MODULE__, guild_id)
  end

  def start_link(guild_id) do
    GenServer.start_link(__MODULE__, guild_id)
  end

  def init(guild_id) do
    channel = Application.fetch_env!(:hosscoinbot, :play_channel_id)
    :ok = Voice.join_channel(guild_id, channel)
    :timer.sleep(2000) # Sleep for async join
    case Registry.register(registry_name(), registry_key(guild_id), __MODULE__) do
      {:ok, _pid} -> {:ok, %State{guild_id: guild_id}}
      {:error, {:already_registered, _pid}} -> :ignore # Already running
    end
  end

  def handle_call({:add_track, track_uri}, _from, state = %State{currently_playing: :not_playing}) do
    {:ok, player_monitor_ref} = play_track(state.guild_id, track_uri) # TODO: Intelligently handle errors playing without blowing up the server
    {:reply, {:ok, :playing}, %State{ state | currently_playing: URI.new!(track_uri), player_monitor_ref: player_monitor_ref }}
  end

  def handle_call({:add_track, track_uri}, _from, state = %State{currently_playing: %URI{} = _current_track_uri}) do
    updated_queue = :queue.in(track_uri, state.queue)
    {:reply, {:ok, {:queued, :queue.len(updated_queue)}}, %State{ state | queue: updated_queue }}
  end

  def handle_call(:up_next, _from, state) do
    {:reply, state.queue, state}
  end

  def handle_call(:clear, _from, state) do
    ensure_stopped_playing(state.guild_id)
    {:reply, :ok, %State{guild_id: state.guild_id}}
  end

  def handle_info({:DOWN, monitor_ref, :process, _player_pid, :stop}, state) when state.player_monitor_ref == monitor_ref do
    Logger.debug("Player exited cleanly, playing next track if one exists")
    case play_next_track(state.guild_id, state.queue) do
      {currently_playing, remaining_queue, player_monitor_ref} ->
        {:noreply, %State{ state | queue: remaining_queue, currently_playing: currently_playing, player_monitor_ref: player_monitor_ref}}
      {:not_playing, remaining_queue} ->
        {:noreply, %State{ state | queue: remaining_queue, currently_playing: :not_playing, player_monitor_ref: nil}}
    end
  end

  def handle_info(all, state) do
    Logger.debug("Unhandled msg: #{inspect(all)} State: #{inspect(state)}")
    {:noreply, state}
  end

  def add_track(guild_id, track_url) do
    GenServer.call(guild_jukebox(guild_id), {:add_track, URI.new!(track_url)})
  end

  def up_next(guild_id) do
    GenServer.call(guild_jukebox(guild_id), :up_next)
  end

  def clear(guild_id) do
    GenServer.call(guild_jukebox(guild_id), :clear)
  end

  defp ensure_stopped_playing(guild_id) do
    case Voice.stop(guild_id) do
      :ok -> :ok
      {:error, "Must be connected to voice channel to stop audio."} -> :ok
    end
  end

  defp play_next_track(guild_id, queue) do
    case :queue.out(queue) do
      {{:value, play_now_track_uri}, remaining_tracks} ->
        {:ok, player_monitor_ref} = play_track(guild_id, play_now_track_uri)
        {play_now_track_uri, remaining_tracks, player_monitor_ref}
      {:empty, remaining_tracks} -> {:not_playing, remaining_tracks}
    end
  end


  defp play_track(guild_id, track_uri) do
    case Voice.play(guild_id, URI.to_string(track_uri), :ytdl, realtime: true) do
      :ok ->
        player_pid = current_player_pid(guild_id)
        player_monitor_ref = Process.monitor(player_pid)
        {:ok, player_monitor_ref}
      {:error, msg} -> {:error, msg}
    end
  end

  def current_player_pid(guild_id), do: Voice.get_voice(guild_id).player_pid

  defp guild_jukebox(guild_id) do
    [{pid, _value}] = Registry.lookup(registry_name(), registry_key(guild_id))
    pid
  end

  defp registry_key(guild_id), do: "#{__MODULE__}-#{guild_id}"

  def registry_name(), do: Hosscoinbot.Jukebox.Registry
end
