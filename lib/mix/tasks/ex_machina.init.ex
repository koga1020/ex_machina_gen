defmodule Mix.Tasks.ExMachina.Init do
  use Mix.Task

  def run(args) do
    {option, _, _} = OptionParser.parse(args, strict: [ecto: :boolean])

    ecto_option = Keyword.get(option, :ecto, true)

    binding = [
      module: Mix.Project.config()[:app] |> to_string() |> Macro.camelize(),
      ecto: ecto_option
    ]

    Mix.Generator.create_file(
      "test/support/factory/factory.ex",
      EEx.eval_file("priv/templates/ex_machina.init/factory.ex", binding)
    )
  end
end
