defmodule Mix.Tasks.ExMachina.Init do
  @shortdoc "Generate factory from Ecto schema module"
  @moduledoc """
  Generate main factory file.

      mix ex_machina.init

  ## Options

  * `--no-ecto` - use `Exmachina` without using `ExMachina.Ecto`

  """
  use Mix.Task
  alias Mix.ExMachinaGen

  def run(args \\ []) do
    {option, _, _} = OptionParser.parse(args, strict: [ecto: :boolean])

    ecto_option = Keyword.get(option, :ecto, true)

    binding = [
      module: Mix.Project.config()[:app] |> to_string() |> Macro.camelize(),
      ecto: ecto_option
    ]

    Mix.ExMachinaGen.create_file(
      ExMachinaGen.main_factory_file_path(),
      "priv/templates/ex_machina.init/factory.ex",
      binding
    )
  end
end
