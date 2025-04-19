defmodule BotMonitorTest do
  use ExUnit.Case
  doctest BotMonitor

  test "greets the world" do
    assert BotMonitor.hello() == :world
  end
end
