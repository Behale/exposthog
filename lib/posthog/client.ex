defmodule Posthog.Client do
  @moduledoc false

  def capture(event, distinct_id, set_person_params, set_once_person_params, timestamp) when is_bitstring(distinct_id) do
    capture(event, %{distinct_id: distinct_id}, set_person_params, set_once_person_params, timestamp)
  end

  def capture(event, event_params, set_person_params, set_once_person_params, timestamp) when is_map(event_params) do
    params =
      event_params
      |> Map.put(:"$set", set_person_params)
      |> Map.put(:"$set_once", set_once_person_params)

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
    %{
      event: to_string(event),
      properties: properties |> Map.new() |> add_metadata(),
      timestamp: timestamp
    }
  end

  defp post!(path, %{} = body) do
    body =
      body
      |> Map.put(:api_key, api_key())
      |> json_library().encode!()

    api_url()
    |> URI.merge(path)
    |> URI.to_string()
    |> :hackney.post([{"Content-Type", "application/json"}], body)
    |> handle()
  end

  defp add_metadata(properties, _metadata \\ %{}) do
    properties
    |> Map.update!(:"$set", &
      &1
      |> Map.new()
      |> Map.put(:env, System.get_env("RELEASE_LEVEL") || Mix.env())
    )
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
    case Application.get_env(:exposthog, :api_url) do
      url when is_bitstring(url) ->
        url

      term ->
        raise """
        Expected a string API URL, got: #{inspect(term)}. Set a
        URL and key in your config:

            config :exposthog,
              api_url: "https://posthog.example.com",
              api_key: "my-key"
        """
    end
  end

  defp api_key() do
    case Application.get_env(:exposthog, :api_key) do
      key when is_bitstring(key) ->
        key

      term ->
        raise """
        Expected a string API key, got: #{inspect(term)}. Set a
        URL and key in your config:

            config :exposthog,
              api_url: "https://posthog.example.com",
              api_key: "my-key"
        """
    end
  end

  defp json_library() do
    Application.get_env(:posthog, :json_library, Jason)
  end
end
