defmodule ExSlop.Check.Warning.RescueWithoutReraiseTest do
  use Credo.Test.Case

  alias ExSlop.Check.Warning.RescueWithoutReraise

  test "reports rescue that logs and returns generic :error" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e ->
            Logger.error("Failed: \#{inspect(e)}")
            :error
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> assert_issue()
  end

  test "reports rescue that logs and returns {:error, static_reason}" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e ->
            Logger.error("Failed: \#{inspect(e)}")
            {:error, :something_failed}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> assert_issue()
  end

  test "reports rescue that logs and returns nil" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e ->
            Logger.error("Failed: \#{inspect(e)}")
            nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> assert_issue()
  end

  test "allows rescue that logs and re-raises" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e ->
            Logger.error("Failed: \#{inspect(e)}")
            reraise e, __STACKTRACE__
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> refute_issues()
  end

  test "allows rescue that returns the exception in error tuple" do
    """
    defmodule Test do
      def transform(data) do
        try do
          do_transform(data)
        rescue
          error ->
            Logger.error("Transform failed: \#{inspect(error)}")
            {:error, {:transform_failed, error}}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> refute_issues()
  end

  test "allows rescue that returns the exception directly in error tuple" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e ->
            Logger.error("oops")
            {:error, e}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> refute_issues()
  end

  test "allows rescue that returns Exception.message in error tuple" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e in RuntimeError ->
            Logger.error("Failed")
            {:error, Exception.message(e)}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> refute_issues()
  end

  test "allows rescue without Logger call" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          e -> {:error, :failed}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> refute_issues()
  end

  test "allows rescue with underscore-prefixed binding" do
    """
    defmodule Test do
      def foo do
        try do
          something()
        rescue
          _e ->
            Logger.error("Failed")
            :error
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(RescueWithoutReraise)
    |> refute_issues()
  end
end
