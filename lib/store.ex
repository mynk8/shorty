defmodule Shorty.Store do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(code) do
    Agent.get(__MODULE__, &Map.get(&1, code))
  end

  def put_new(code, url) do
    Agent.get_and_update(__MODULE__, fn state ->
      if Map.has_key?(state, code) do
        {{:error, :exists}, state}
      else
        {{:ok, code}, Map.put(state, code, url)}
      end
    end)
  end
end
