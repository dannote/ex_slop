defmodule ExSlopTest do
  use ExUnit.Case

  test "init/1 is exported for Credo plugin interface" do
    assert Code.ensure_loaded?(ExSlop)
    assert function_exported?(ExSlop, :init, 1)
  end

  test "recommended_checks returns the recommended subset" do
    recommended = ExSlop.recommended_checks()
    all = ExSlop.checks()

    assert [_ | _] = recommended
    assert Enum.all?(recommended, &(&1 in all))
  end

  test "checks includes ported Credence-inspired checks" do
    assert ExSlop.Check.Refactor.UseMapJoin in ExSlop.checks()
    assert ExSlop.Check.Refactor.LengthInGuard in ExSlop.checks()
  end
end
