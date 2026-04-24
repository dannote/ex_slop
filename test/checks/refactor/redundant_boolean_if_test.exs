defmodule ExSlop.Check.Refactor.RedundantBooleanIfTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.RedundantBooleanIf

  test "reports if cond, do: true, else: false" do
    """
    defmodule Example do
      def check(x) do
        if x > 0, do: true, else: false
      end
    end
    """
    |> to_source_file()
    |> run_check(RedundantBooleanIf)
    |> assert_issue()
  end

  test "reports if cond, do: false, else: true" do
    """
    defmodule Example do
      def check(x) do
        if x == nil, do: false, else: true
      end
    end
    """
    |> to_source_file()
    |> run_check(RedundantBooleanIf)
    |> assert_issue()
  end

  test "reports assignment of redundant boolean if" do
    """
    defmodule Example do
      def check(x) do
        is_active = if x > 0, do: true, else: false
        is_active
      end
    end
    """
    |> to_source_file()
    |> run_check(RedundantBooleanIf)
    |> assert_issue()
  end

  test "does NOT report if with non-boolean literals" do
    """
    defmodule Example do
      def check(x) do
        if x > 0, do: :ok, else: :error
      end
    end
    """
    |> to_source_file()
    |> run_check(RedundantBooleanIf)
    |> refute_issues()
  end

  test "does NOT report if with string boolean-like values" do
    """
    defmodule Example do
      def check(x) do
        if x > 0, do: "true", else: "false"
      end
    end
    """
    |> to_source_file()
    |> run_check(RedundantBooleanIf)
    |> refute_issues()
  end

  test "does NOT report normal if/else" do
    """
    defmodule Example do
      def check(x) do
        if x > 0 do
          calculate_positive(x)
        else
          calculate_negative(x)
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RedundantBooleanIf)
    |> refute_issues()
  end
end
