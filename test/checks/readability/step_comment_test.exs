defmodule ExSlop.Check.Readability.StepCommentTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.StepComment

  test "reports '# Step 1:' comments" do
    """
    defmodule Test do
      def foo do
        # Step 1: Validate the input
        validate()
        # Step 2: Transform the data
        transform()
      end
    end
    """
    |> to_source_file()
    |> run_check(StepComment)
    |> assert_issues(fn issues -> assert length(issues) == 2 end)
  end

  test "does NOT report non-step comments" do
    """
    defmodule Test do
      def foo do
        # Validate the input
        validate()
      end
    end
    """
    |> to_source_file()
    |> run_check(StepComment)
    |> refute_issues()
  end
end
