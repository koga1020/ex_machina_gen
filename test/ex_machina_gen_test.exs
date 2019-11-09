defmodule ExMachinaGenTest do
  use ExUnit.Case
  doctest ExMachinaGen

  test "greets the world" do
    assert ExMachinaGen.hello() == :world
  end
end
