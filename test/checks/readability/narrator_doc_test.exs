defmodule ExSlop.Check.Readability.NarratorDocTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.NarratorDoc

  test "reports @moduledoc starting with 'This module provides'" do
    ~S'''
    defmodule Test do
      @moduledoc """
      This module provides functionality for handling user authentication.
      """
    end
    '''
    |> to_source_file()
    |> run_check(NarratorDoc)
    |> assert_issue()
  end

  test "reports @doc starting with 'This function handles'" do
    ~S'''
    defmodule Test do
      @doc """
      This function handles the creation of a new user.
      """
      def create_user(attrs), do: attrs
    end
    '''
    |> to_source_file()
    |> run_check(NarratorDoc)
    |> assert_issue()
  end

  test "reports @moduledoc with 'The `Foo` module provides'" do
    ~S'''
    defmodule Foo do
      @moduledoc """
      The `Foo` module provides an API for managing widgets.
      """
    end
    '''
    |> to_source_file()
    |> run_check(NarratorDoc)
    |> assert_issue()
  end

  test "does NOT report meaningful @moduledoc" do
    ~S'''
    defmodule Test do
      @moduledoc """
      Wraps Bcrypt and session token generation.
      Rate-limits login attempts per IP via a sliding window.
      """
    end
    '''
    |> to_source_file()
    |> run_check(NarratorDoc)
    |> refute_issues()
  end

  test "does NOT report @moduledoc false" do
    """
    defmodule Test do
      @moduledoc false
    end
    """
    |> to_source_file()
    |> run_check(NarratorDoc)
    |> refute_issues()
  end

  test "does NOT report @doc with examples" do
    ~S'''
    defmodule Test do
      @doc """
      This function creates a new user.

      ## Examples

          iex> create_user(%{name: "Dan"})
          {:ok, %User{}}
      """
      def create_user(attrs), do: attrs
    end
    '''
    |> to_source_file()
    |> run_check(NarratorDoc)
    |> refute_issues()
  end
end
