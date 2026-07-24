defmodule ExSlop.Plugin.ActivationWarning do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Output.UI

  @impl true
  def call(exec, _opts) do
    if not active?(exec), do: warn()

    exec
  end

  @doc false
  def active?(%Execution{checks: %{enabled: enabled}}) when is_list(enabled) do
    Enum.any?(enabled, fn
      {_module, false} -> false
      {module, _params} -> module in ExSlop.checks()
    end)
  end

  # Stay quiet when the ExSlop check set can't be determined.
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
