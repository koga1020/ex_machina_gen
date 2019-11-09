defmodule Mix.Tasks.ExMachina.Gen do
  use Mix.Task

  def run(args) do
    [schema_string] = validate_args(args)
    schema_module = Module.concat([Elixir, schema_string])

    fields = apply(schema_module, :__schema__, [:fields])
    [primary_key] = apply(schema_module, :__schema__, [:primary_key])

    assoc_field_keys =
      apply(schema_module, :__schema__, [:associations])
      |> Enum.map(fn assoc_field ->
        apply(schema_module, :__schema__, [:association, assoc_field])
      end)
      |> Enum.map(fn assoc_struct -> assoc_struct.owner_key end)

    struct_string =
      fields
      |> List.delete(primary_key)
      |> Kernel.--(assoc_field_keys)
      |> to_attrs_map(schema_module)
      |> inspect(pretty: true, width: :infinity)
      |> String.replace_leading("%{", "%#{schema_string}{")

    singular = apply(schema_module, :__schema__, [:source]) |> Inflex.singularize()

    binding = [
      module: schema_string,
      singular: singular,
      struct_string: struct_string
    ]

    Mix.Generator.create_file(
      "test/support/factory/#{singular}_factory.ex",
      EEx.eval_file("priv/templates/ex_machina.gen/factory.ex", binding)
    )
  end

  defp to_attrs_map(fields, schema_module) do
    fields
    |> Enum.map(fn field ->
      type = apply(schema_module, :__schema__, [:type, field])
      {field, example_val(field, type)}
    end)
    |> Enum.into(%{})
  end

  defp example_val(field, :string), do: "test #{field}"
  defp example_val(_, :map), do: %{}
  defp example_val(_, :boolean), do: true
  defp example_val(_, :utc_datetime), do: ~U[2019-01-01 00:00:00Z]

  def validate_args([_] = args), do: args

  def validate_args(_) do
    Mix.raise("""
    Invalid arguments

    mix ex_machina.gen expects schema module name:

      mix ex_machina.gen Blog.Post
    """)
  end
end
