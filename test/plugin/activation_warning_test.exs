defmodule ExSlop.Plugin.ActivationWarningTest do
  use ExUnit.Case, async: true

  alias ExSlop.Plugin.ActivationWarning

  test "active? is true when an ExSlop check is enabled" do
    exec = %Credo.Execution{
      checks: %{
        enabled: [{Credo.Check.Readability.ModuleDoc, []}, {ExSlop.Check.Refactor.RejectNil, []}]
      }
    }

    assert ActivationWarning.active?(exec)
  end

  test "active? is false when only non-ExSlop checks are enabled" do
    exec = %Credo.Execution{
      checks: %{enabled: [{Credo.Check.Readability.ModuleDoc, []}]}
    }

    refute ActivationWarning.active?(exec)
  end

  test "active? stays quiet (true) when the check set is unknown" do
    assert ActivationWarning.active?(%Credo.Execution{checks: nil})
  end

  test "call/2 returns the exec unchanged" do
    exec = %Credo.Execution{checks: %{enabled: [{Credo.Check.Readability.ModuleDoc, []}]}}

    assert ActivationWarning.call(exec, []) == exec
  end
end
