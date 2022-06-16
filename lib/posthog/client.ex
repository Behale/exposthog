defmodule Posthog.Client do
  @moduledoc false

  def capture(event, distinct_id, set_params, set_once_params, timestamp) when (is_bitstring(event) or is_atom(event)) and is_bitstring(distinct_id) do
    params = [
      distinct_id: distinct_id,
      "$set": set_params,
      "$set_once": set_once_params,
    ]

    body = build_event(event, params, timestamp)

    post!("/capture", body)
  end

  def capture(event, params, timestamp) when is_bitstring(event) or is_atom(event) do
    body = build_event(event, params, timestamp)

    post!("/capture", body)
  end

  def identify(distinct_id, timestamp) when is_bitstring(distinct_id) do
    body = build_event("$identify", [distinct_id: distinct_id], timestamp)

    post!("/capture", body)
  end

  def batch(events) when is_list(events) do
    body =
      for {event, params, timestamp} <- events do
        build_event(event, params, timestamp)
      end

    body = %{batch: body}

    post!("/capture", body)
  end

  defp build_event(event, properties, timestamp) do
    %{event: to_string(event), properties: Map.new(properties), timestamp: timestamp}
  end

  defp post!(path, %{} = body) do
    body =
      body
      |> Map.put(:api_key, api_key())
      |> add_metadata()
      |> json_library().encode!()

    api_url()
    |> URI.merge(path)
    |> URI.to_string()
    |> :hackney.post([{"Content-Type", "application/json"}], body)
    |> handle()
  end

  defp add_metadata(body, _metadata) do
    body
    |> Map.put(:env, Mix.env())
  end

  @spec handle(tuple()) :: {:ok, term()} | {:error, term()}
  defp handle({:ok, status, _headers, _ref} = resp) when div(status, 100) == 2 do
    {:ok, to_response(resp)}
  end

  defp handle({:ok, _status, _headers, _ref} = resp) do
    {:error, to_response(resp)}
  end

  defp handle({:error, _} = result) do
    result
  end

  defp to_response({_, status, headers, ref}) do
    response = %{status: status, headers: headers, body: nil}

    with {:ok, body} <- :hackney.body(ref),
         {:ok, json} <- json_library().decode(body) do
      %{response | body: json}
    else
      _ -> response
    end
  end

  defp api_url() do
    case Application.get_env(:posthog, :api_url) do
      url when is_bitstring(url) ->
        url

      term ->
        raise """
        Expected a string API URL, got: #{inspect(term)}. Set a
        URL and key in your config:

            config :posthog,
              api_url: "https://posthog.example.com",
              api_key: "my-key"
        """
    end
  end

  defp api_key() do
    case Application.get_env(:posthog, :api_key) do
      key when is_bitstring(key) ->
        key

      term ->
        raise """
        Expected a string API key, got: #{inspect(term)}. Set a
        URL and key in your config:

            config :posthog,
              api_url: "https://posthog.example.com",
              api_key: "my-key"
        """
    end
  end

  defp json_library() do
    Application.get_env(:posthog, :json_library, Jason)
  end
end
