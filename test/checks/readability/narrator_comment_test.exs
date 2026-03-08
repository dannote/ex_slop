defmodule ExSlop.Check.Readability.NarratorCommentTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.NarratorComment

  test "reports 'Here we fetch the user'" do
    """
    defmodule Test do
      def foo do
        # Here we fetch the user
        Repo.get(User, id)
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> assert_issue()
  end

  test "reports 'Now we validate the input'" do
    """
    defmodule Test do
      def foo do
        # Now we validate the input
        validate(input)
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> assert_issue()
  end

  test "reports 'Let's create a new changeset'" do
    """
    defmodule Test do
      def foo do
        # Let's create a new changeset
        change(user)
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> assert_issue()
  end

  test "reports 'First, we check if the user exists'" do
    """
    defmodule Test do
      def foo do
        # First, we check if the user exists
        Repo.exists?(User, id: id)
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> assert_issue()
  end

  test "does NOT report long comment (>60 chars)" do
    """
    defmodule Test do
      def foo do
        # Here we use a CTE because recursive queries are faster than iterative lookups
        query()
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> refute_issues()
  end

  test "does NOT report comment with explanation (because/since/so we)" do
    """
    defmodule Test do
      def foo do
        # Now we trap messages so we can collect warnings
        run()
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> refute_issues()
  end

  test "does NOT report comment with 'cannot'/'avoid' reasoning" do
    """
    defmodule Test do
      def foo do
        # Here we cannot use colors because IEx may be off
        print()
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> refute_issues()
  end

  test "does NOT report TODO comments" do
    """
    defmodule Test do
      def foo do
        # TODO: Here we should add caching
        fetch()
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> refute_issues()
  end

  test "does NOT report non-narrator comments" do
    """
    defmodule Test do
      def foo do
        # Calculate the checksum
        checksum(data)
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> refute_issues()
  end

  test "does NOT report 'We need/We can/We first' (common Elixir style)" do
    """
    defmodule Test do
      def foo do
        # We need this check for bootstrap
        check()
        # We can optimize this later
        compute()
        # We first look at the signal
        handle()
      end
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> refute_issues()
  end

  test "does NOT report narrator text inside @doc heredoc" do
    """
    defmodule Test do
      @doc \"""
      Here we explain how the function works.
      \"""
      def foo, do: :ok
    end
    """
    |> to_source_file()
    |> run_check(NarratorComment)
    |> refute_issues()
  end
end
