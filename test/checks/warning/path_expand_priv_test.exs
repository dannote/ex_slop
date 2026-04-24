defmodule ExSlop.Check.Warning.PathExpandPrivTest do
  use Credo.Test.Case

  alias ExSlop.Check.Warning.PathExpandPriv

  test "reports Path.expand with priv and __DIR__" do
    """
    defmodule MyModule do
      def system_prompt do
        Path.expand("../../priv/prompts/system.md", __DIR__)
      end
    end
    """
    |> to_source_file()
    |> run_check(PathExpandPriv)
    |> assert_issue()
  end

  test "reports Path.expand with priv in binary interpolation" do
    """
    defmodule MyModule do
      def template_path(name) do
        Path.expand("priv/templates/\#{name}.md", __DIR__)
      end
    end
    """
    |> to_source_file()
    |> run_check(PathExpandPriv)
    |> assert_issue()
  end

  test "does NOT report Path.expand without priv" do
    """
    defmodule MyModule do
      def config_path do
        Path.expand("../config/config.exs", __DIR__)
      end
    end
    """
    |> to_source_file()
    |> run_check(PathExpandPriv)
    |> refute_issues()
  end

  test "does NOT report Application.app_dir" do
    """
    defmodule MyModule do
      def system_prompt do
        Application.app_dir(:my_app, "priv/prompts/system.md")
      end
    end
    """
    |> to_source_file()
    |> run_check(PathExpandPriv)
    |> refute_issues()
  end
end
