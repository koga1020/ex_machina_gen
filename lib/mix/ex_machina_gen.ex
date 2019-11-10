defmodule Mix.ExMachinaGen do
  # Conveniences for ExMachinaGen tasks.
  @moduledoc false

  @doc false
  def create_file(path, contents_path, binding) do
    Mix.Generator.create_file(
      path,
      EEx.eval_file(app_path(contents_path), binding)
    )
  end

  @doc false
  def app_path(paths) do
    Application.app_dir(:ex_machina_gen, paths)
  end
end
