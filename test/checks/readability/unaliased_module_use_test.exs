defmodule ExSlop.Check.Readability.UnaliasedModuleUseTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.UnaliasedModuleUse

  test "reports repeated unaliased module use" do
    """
    defmodule Test do
      def foo(source_file) do
        Credo.Code.prewalk(source_file, &walk/2, [])
        Credo.Code.remove_metadata(source_file)
      end
    end
    """
    |> to_source_file()
    |> run_check(UnaliasedModuleUse)
    |> assert_issues(fn issues ->
      assert length(issues) == 2
      assert Enum.all?(issues, &(&1.trigger == "Credo.Code"))
    end)
  end

  test "does NOT report when module is aliased" do
    """
    defmodule Test do
      alias Credo.Code

      def foo(source_file) do
        Code.prewalk(source_file, &walk/2, [])
        Code.remove_metadata(source_file)
      end
    end
    """
    |> to_source_file()
    |> run_check(UnaliasedModuleUse)
    |> refute_issues()
  end

  test "does NOT report when module is aliased with 'as:'" do
    """
    defmodule Test do
      alias Credo.SourceFile, as: SF

      def foo do
        SF.lines(:ok)
      end
    end
    """
    |> to_source_file()
    |> run_check(UnaliasedModuleUse)
    |> refute_issues()
  end

  test "does NOT report when used only once (below min_count)" do
    """
    defmodule Test do
      def foo do
        Credo.Code.prewalk(:ok)
      end
    end
    """
    |> to_source_file()
    |> run_check(UnaliasedModuleUse)
    |> refute_issues()
  end

  test "does NOT report single-segment modules" do
    """
    defmodule Test do
      def foo do
        Enum.map([1, 2, 3], & &1)
        Enum.filter([1, 2, 3], & &1 > 1)
      end
    end
    """
    |> to_source_file()
    |> run_check(UnaliasedModuleUse)
    |> refute_issues()
  end

  test "respects min_count param" do
    """
    defmodule Test do
      def foo do
        Credo.Code.prewalk(:ok)
        Credo.Code.remove_metadata(:ok)
        Credo.Code.prewalk(:ok)
      end
    end
    """
    |> to_source_file()
    |> run_check(UnaliasedModuleUse, min_count: 3)
    |> assert_issues(fn issues ->
      assert length(issues) == 3
      assert Enum.all?(issues, &(&1.trigger == "Credo.Code"))
    end)
  end

  test "does NOT report inside module attributes" do
    """
    defmodule Test do
      @type t :: Credo.Code.t()
      @spec foo() :: Credo.Code.t()

      def foo do
        :ok
      end
    end
    """
    |> to_source_file()
    |> run_check(UnaliasedModuleUse)
    |> refute_issues()
  end
end
