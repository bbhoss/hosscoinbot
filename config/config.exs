import Config

config :nostrum,
  token: "snip",
  num_shards: :auto

config :hosscoinbot,
  ecto_repos: [Hosscoinbot.Repo]

config :hosscoinbot, Hosscoinbot.Repo,
  database: "db/db.sqlite3"
