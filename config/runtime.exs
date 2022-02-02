import Config

if System.get_env("DISCORD_TOKEN") do
  config :nostrum,
    token: System.get_env("DISCORD_TOKEN"),
    num_shards: :auto
end

if System.get_env("DB_PATH") do
  config :hosscoinbot, Hosscoinbot.Repo,
    database: System.get_env("DB_PATH")
end
