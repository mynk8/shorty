defmodule Shorty.Shortener do
  def create(url, tries \\ 5)

  def create(_url, 0), do: {:error, :could_not_generate_code}

  def create(url, tries) do
    code = Shorty.Code.generate()

    case Shorty.Store.put_new(code, url) do
      {:ok, ^code} -> {:ok, code}
      {:error, :exists} -> create(url, tries - 1)
    end
  end
end
