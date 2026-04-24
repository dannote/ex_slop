defmodule ExSlop.Check.Warning.DualKeyAccessTest do
  use Credo.Test.Case

  alias ExSlop.Check.Warning.DualKeyAccess

  test "reports Map.get with atom || Map.get with matching string" do
    """
    defmodule Example do
      def extract(usage) do
        input = Map.get(usage, :input_tokens) || Map.get(usage, "input_tokens") || 0
        input
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "does NOT report when atom and string keys differ" do
    """
    defmodule Example do
      def extract(usage) do
        input = Map.get(usage, :input_tokens) || Map.get(usage, "input_count")
        input
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report single Map.get" do
    """
    defmodule Example do
      def extract(usage) do
        Map.get(usage, :input_tokens, 0)
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report Map.get with different maps" do
    """
    defmodule Example do
      def extract(a, b) do
        Map.get(a, :key) || Map.get(b, "key")
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end
end
