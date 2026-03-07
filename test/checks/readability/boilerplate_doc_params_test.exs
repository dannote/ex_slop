defmodule ExSlop.Check.Readability.BoilerplateDocParamsTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.BoilerplateDocParams

  test "reports @doc with boilerplate ## Parameters section" do
    ~S'''
    defmodule Test do
      @doc """
      Renders the index page.

      ## Parameters

      - conn: The connection struct
      - params: A map of parameters
      """
      def index(conn, params), do: {conn, params}
    end
    '''
    |> to_source_file()
    |> run_check(BoilerplateDocParams)
    |> assert_issue()
  end

  test "reports @doc with ## Args and socket boilerplate" do
    ~S'''
    defmodule Test do
      @doc """
      Handles the event.

      ## Args

      - socket: The socket
      - assigns: The assigns map
      """
      def handle_event(socket, assigns), do: {socket, assigns}
    end
    '''
    |> to_source_file()
    |> run_check(BoilerplateDocParams)
    |> assert_issue()
  end

  test "does NOT report @doc with meaningful parameter descriptions" do
    ~S'''
    defmodule Test do
      @doc """
      Renders the index page.

      ## Parameters

      - params: Must include `"page"` (integer >= 1) and
        optionally `"per_page"` (default 20, max 100).
      """
      def index(conn, params), do: {conn, params}
    end
    '''
    |> to_source_file()
    |> run_check(BoilerplateDocParams)
    |> refute_issues()
  end

  test "does NOT report @doc without ## Parameters" do
    ~S'''
    defmodule Test do
      @doc """
      Renders the index page, paginated.
      """
      def index(conn, params), do: {conn, params}
    end
    '''
    |> to_source_file()
    |> run_check(BoilerplateDocParams)
    |> refute_issues()
  end
end
