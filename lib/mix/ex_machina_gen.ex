defmodule Mix.ExMachinaGen do
  # Conveniences for ExMachinaGen tasks.
  @moduledoc false

  @app :ex_machina_gen

  @doc false
  def create_file(path, contents_path, binding) do
    Mix.Generator.create_file(
      path,
      EEx.eval_file(app_path(contents_path), binding)
    )
  end

  @doc false
  def app_path(paths) do
    Application.app_dir(@app, paths)
  end

  @doc false
  def main_factory_file_path() do
    Path.join([factory_dir(), "factory.ex"])
  end

  @doc false
  def factory_file_path(singular) do
    Path.join([factory_dir(), "#{singular}_factory.ex"])
  end

  @doc false
  def factory_dir() do
    Application.get_env(@app, :factory_dir, "test/support/factory")
  end
end
