defmodule Posthog do
  @moduledoc """
  This module provides an Elixir HTTP client for Posthog.

  Example config:

      config :posthog,
        api_url: "http://posthog.example.com",
        api_key: "..."

  Optionally, you can pass in a `:json_library` key. The default JSON parser
  is Jason.
  """

  @doc """
  Sends a capture event. `distinct_id` is the only required parameter.

  ## Examples

      iex> Posthog.capture("login", distinct_id: user.id)
      :ok
      iex> Posthog.capture("login", [distinct_id: user.id], DateTime.utc_now())
      :ok

  """
  @typep result() :: {:ok, term()} | {:error, term()}
  @typep timestamp() :: DateTime.t() | NaiveDateTime.t() | String.t() | nil

  @spec capture(atom() | String.t(), String.t(), map(), map(), timestamp()) :: result()
  defdelegate capture(event, distinct_id, set_params \\ %{}, set_once_parms \\ %{}, timestamp \\ nil), to: Posthog.Client

  @spec capture(atom() | String.t(), keyword() | map(), timestamp()) :: result()
  defdelegate capture(event, params, timestamp \\ nil), to: Posthog.Client

  @spec identify(String.t(), keyword() | map(), timestamp()) :: result()
  defdelegate identify(distinct_id, timestamp \\ nil), to: Posthog.Client

  @spec batch(list(tuple())) :: result()
  defdelegate batch(events), to: Posthog.Client
end
