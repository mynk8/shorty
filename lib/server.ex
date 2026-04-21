defmodule Shorty.Server do
  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true
      ])

    send(self(), :accept)
    {:ok, listen_socket}
  end

  def handle_info(:accept, listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)
    Task.start(fn -> handle_client(client_socket) end)
    send(self(), :accept)
    {:noreply, listen_socket}
  end

  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, request} ->
        response =
          request
          |> to_string()
          |> Shorty.HTTP.handle()

        :gen_tcp.send(socket, response)
        :gen_tcp.close(socket)

      {:error, _} ->
        :gen_tcp.close(socket)
    end
  end
end
