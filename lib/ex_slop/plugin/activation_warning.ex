defmodule ExSlop.Plugin.ActivationWarning do
  @moduledoc """
  Warns when ExSlop is registered as a plugin but none of its checks are active.
  """

  use Credo.Execution.Task

  alias Credo.CLI.Output.UI

  @impl true
  def call(exec, _opts) do
    if not active?(exec), do: warn()

    exec
  end

  @doc """
  Returns `true` when at least one ExSlop check is in the resolved `enabled` set.
  """
  def active?(%Credo.Execution{checks: %{enabled: enabled}}) when is_list(enabled) do
    Enum.any?(enabled, fn {mod, _params} -> mod in ExSlop.checks() end)
  end

  # Returns `true` when the ExSlop check set can't be determined
  def active?(_exec), do: true

  defp warn do
    UI.warn([
      :yellow,
      "warning: ",
      :reset,
      "ExSlop is registered as a plugin but none of its checks are active. ",
      "Your `.credo.exs` declares an explicit `checks.enabled` list, which Credo ",
      "treats as authoritative — the plugin's default checks are discarded. ",
      "Append them to your `enabled` list:\n\n",
      "    ] ++ Enum.map(ExSlop.recommended_checks(), &{&1, []}),\n"
    ])
  end
end
