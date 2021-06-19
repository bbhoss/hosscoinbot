defmodule HosscoinbotTest do
  use ExUnit.Case
  doctest Hosscoinbot

  test "greets the world" do
    assert Hosscoinbot.hello() == :world
  end
end
