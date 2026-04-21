defmodule Shorty.HTTP do
  def handle(request) do
    case parse_request(request) do
      {:ok, method, path, _headers, body} ->
        route(method, path, body)

      :error ->
        response(400, "Bad Request", "bad request")
    end
  end

  defp parse_request(request) do
    case String.split(request, "\r\n\r\n", parts: 2) do
      [head, body] ->
        lines = String.split(head, "\r\n")

        case lines do
          [request_line | header_lines] ->
            case String.split(request_line, " ", parts: 3) do
              [method, path, _version] ->
                headers = parse_headers(header_lines)
                {:ok, method, path, headers, body}

              _ ->
                :error
            end

          _ ->
            :error
        end

      [head] ->
        lines = String.split(head, "\r\n")

        case lines do
          [request_line | header_lines] ->
            case String.split(request_line, " ", parts: 3) do
              [method, path, _version] ->
                headers = parse_headers(header_lines)
                {:ok, method, path, headers, ""}

              _ ->
                :error
            end

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  defp parse_headers(lines) do
    Enum.reduce(lines, %{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [k, v] -> Map.put(acc, String.downcase(String.trim(k)), String.trim(v))
        _ -> acc
      end
    end)
  end

  defp route("GET", "/", _body) do
    response(200, "OK", "shorty alive")
  end

  defp route("POST", "/shorten", body) do
    url = String.trim(body)

    cond do
      url == "" ->
        response(400, "Bad Request", "missing url")

      not valid_url?(url) ->
        response(400, "Bad Request", "invalid url")

      true ->
        case Shorty.Shortener.create(url) do
          {:ok, code} ->
            response(201, "Created", "http://localhost:4000/" <> code)

          {:error, :could_not_generate_code} ->
            response(500, "Internal Server Error", "could not generate code")
        end
    end
  end

  defp route("GET", "/" <> code, _body) do
    case Shorty.Store.get(code) do
      nil ->
        response(404, "Not Found", "short code not found")

      url ->
        redirect_response(url)
    end
  end

  defp route(_, _, _) do
    response(404, "Not Found", "not found")
  end

  defp valid_url?(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        true

      _ ->
        false
    end
  end

  defp response(status, reason, body) do
    [
      "HTTP/1.1 ",
      Integer.to_string(status),
      " ",
      reason,
      "\r\n",
      "content-type: text/plain\r\n",
      "content-length: ",
      Integer.to_string(byte_size(body)),
      "\r\n",
      "connection: close\r\n",
      "\r\n",
      body
    ]
    |> IO.iodata_to_binary()
  end

  defp redirect_response(url) do
    [
      "HTTP/1.1 302 Found\r\n",
      "location: ",
      url,
      "\r\n",
      "content-length: 0\r\n",
      "connection: close\r\n",
      "\r\n"
    ]
    |> IO.iodata_to_binary()
  end
end
