defmodule Hosscoinbot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Hosscoinbot.Bot,
      Hosscoinbot.Repo,
      {Registry, name: Hosscoinbot.Jukebox.registry_name, keys: :unique}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hosscoinbot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
