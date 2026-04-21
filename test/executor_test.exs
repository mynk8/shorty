defmodule ExecutorTest do
  use ExUnit.Case
  doctest Executor

  test "adds two numbers" do
    assert Executor.add(2, 3) == 5
  end
end
