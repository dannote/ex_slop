defmodule Mix.Tasks.Dogfood do
  @shortdoc "Run ex_slop checks against its own codebase"
  @moduledoc false
  use Mix.Task

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    source_files =
      Path.wildcard("lib/**/*.ex")
      |> Enum.map(fn path ->
        source = File.read!(path)
        Credo.SourceFile.parse(source, path)
      end)
      |> Enum.reject(&(&1.status == :timed_out))

    issues =
      Enum.flat_map(ExSlop.checks(), fn check ->
        Enum.flat_map(source_files, fn source_file ->
          check.run(source_file, []) |> List.wrap()
        end)
      end)

    if issues == [] do
      Mix.shell().info([:green, "  ✓ Dogfooding passed — no ex_slop issues in lib/"])
    else
      Enum.each(issues, fn issue ->
        check_name = issue.check |> to_string() |> String.replace("Elixir.", "")

        Mix.shell().info([
          :red,
          "  ✗ #{issue.filename}:#{issue.line_no} [#{check_name}] #{issue.message}"
        ])
      end)

      Mix.raise("Dogfooding failed — ex_slop found #{length(issues)} issue(s)")
    end
  end
end
