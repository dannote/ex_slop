defmodule ExSlop.Plugin.ActivationWarning do
  @moduledoc """
  Warns when ExSlop is registered as a plugin but none of its checks are active.

  This happens when the surrounding `.credo.exs` declares an explicit
  `checks.enabled` list (as `mix credo.gen.config` generates): Credo treats that
  list as authoritative and discards the `checks.extra` set the plugin registers
  as default config, so the plugin silently contributes nothing. The fix is to
  append `ExSlop.recommended_checks/0` to the `enabled` list — this task points
  the user there instead of leaving them to discover it.
  """

  use Credo.Execution.Task

  alias Credo.CLI.Output.UI

  @impl true
  def call(exec, _opts) do
    unless active?(exec) do
      warn()
    end

    exec
  end

  @doc """
  Returns `true` when at least one ExSlop check is in the resolved `enabled` set,
  or when the check set can't be determined (in which case we stay quiet).
  """
  def active?(%Credo.Execution{checks: %{enabled: enabled}}) when is_list(enabled) do
    Enum.any?(enabled, fn {mod, _params} -> mod in ExSlop.checks() end)
  end

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
