defmodule ExSlop.Check.Refactor.WithIdentityElseTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.WithIdentityElse

  test "reports with/else where else is identity" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          {:error, reason} -> {:error, reason}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> assert_issue()
  end

  test "does NOT report with/else where else transforms values" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          {:error, reason} -> {:error, :failed, reason}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> refute_issues()
  end

  test "does NOT report with without else" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> refute_issues()
  end
end
