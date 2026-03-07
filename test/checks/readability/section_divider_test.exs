defmodule ExSlop.Check.Readability.SectionDividerTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.SectionDivider

  test "reports '# ============'" do
    """
    defmodule Test do
      # ============
      def foo, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(SectionDivider)
    |> assert_issue()
  end

  test "reports '# --- Helpers ---'" do
    """
    defmodule Test do
      # --- Helpers ---
      defp bar, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(SectionDivider)
    |> assert_issue()
  end

  test "does NOT report '# TODO: ===='" do
    """
    defmodule Test do
      # TODO: ====== fix this later ======
      def foo, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(SectionDivider)
    |> refute_issues()
  end

  test "does NOT report regular comments" do
    """
    defmodule Test do
      # This is a normal comment
      def foo, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(SectionDivider)
    |> refute_issues()
  end
end
