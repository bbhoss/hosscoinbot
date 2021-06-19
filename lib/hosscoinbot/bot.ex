defmodule Hosscoinbot.Bot do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [Hosscoinbot.TreasuryConsumer]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Hosscoinbot.TreasuryConsumer do
  use Nostrum.Consumer

  @allowed_minters [
    190221514245668864
  ]

  alias Nostrum.Api
  alias Hosscoinbot.Operations
  alias Hosscoinbot.Model.Minting

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    IO.inspect(msg)
    author_id = msg.author.id
    username = msg.author.username
    mentioned = msg.mentions
    case msg.content do
      "$mint " <> amount_s when author_id in @allowed_minters  ->
        case Integer.parse(String.trim(amount_s)) do
          {amount_int, ""} ->
            case Operations.mint_coins(author_id, amount_int) do
              {:ok, %Minting{amount: amount}} ->
                minter_balance = Operations.balance(author_id)
                Api.create_message(msg.channel_id, "Minted #{amount} $HOSS coins. #{username} balance now: #{minter_balance}")
            end
          _ -> Api.create_message(msg.channel_id, "Invalid amount. Usage: \"$mint 1000\"")
        end
      "$transfer " <> rest when length(mentioned) == 1 ->
        without_mentions = String.replace(rest, ~r/<@!\d+>/, "") |> String.trim
        first_mentioned = hd(mentioned)
        with  {amount_i, ""} <- Integer.parse(without_mentions),
              {:ok, txn} <- Operations.transfer(author_id, first_mentioned.id, amount_i)
              do
                Api.create_message(msg.channel_id, "Transferred #{txn.amount} $HOSS coins from #{username} to #{first_mentioned.username}")
              else
                {:error, err_msg} -> Api.create_message(msg.channel_id, "Transfer failed: #{err_msg}")
                _ -> Api.create_message(msg.channel_id, "Transfer failed: Unknown")
              end
      "$balance" ->
        author_balance = Operations.balance(author_id)
        Api.create_message(msg.channel_id, "Your balance: #{author_balance} $HOSS")
      "$balance" <> _rest when length(mentioned) == 1 ->
        mentioned_balance = Operations.balance(hd(mentioned).id)
        Api.create_message(msg.channel_id, "#{hd(mentioned).username} balance: #{mentioned_balance} $HOSS")
      "$log"  <> _rest when length(mentioned) == 1 ->
        first_mentioned = hd(mentioned)
        txns = Operations.user_transactions(first_mentioned.id)
        logs_message = for txn <- txns, into: "", do: "From: #{txn.from_id} To: #{txn.to_id} Amount: #{txn.amount}\n"
        Api.create_message(msg.channel_id, "Transaction Log for #{first_mentioned.username}:\n\n#{logs_message}")
      _ ->
        :ignore
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end
