defmodule Shorty.Code do
  @alphabet 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

  def generate(length \\ 6) do
    for _ <- 1..length, into: "" do
      <<Enum.random(@alphabet)>>
    end
  end
end
