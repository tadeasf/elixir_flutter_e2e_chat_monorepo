defmodule ElixirTest.CoreTest do
  use ExUnit.Case, async: true
  doctest ElixirTest

  describe "core functionality" do
    test "greets the world" do
      assert ElixirTest.hello() == :world
    end

    # Add more core functionality tests here as needed
  end
end
