defmodule Mix.Tasks.ExMachina.Gen do
  @shortdoc "Generate factory from Ecto schema module"

  @moduledoc """
  Generate factory from Ecto schema module.

      mix ex_machina.gen Blog.Post

  """
  use Mix.Task

  def run(args) do
    [schema_string] = validate_args(args)
    schema_module = Module.concat([Elixir, schema_string])

    fields = apply(schema_module, :__schema__, [:fields])
    [primary_key] = apply(schema_module, :__schema__, [:primary_key])
    associations = apply(schema_module, :__schema__, [:associations])

    assoc_field_keys =
      associations
      |> Enum.map(fn assoc_field ->
        apply(schema_module, :__schema__, [:association, assoc_field])
      end)
      |> Enum.map(fn assoc_struct -> assoc_struct.owner_key end)

    struct_string =
      fields
      |> List.delete(primary_key)
      |> Kernel.--(assoc_field_keys)
      |> to_attrs_map(schema_module)
      |> put_assoc_build(schema_module, associations)
      |> inspect(pretty: true, width: :infinity)
      |> String.replace_leading("%{", "%#{schema_string}{")
      |> String.replace(~r/"build\((.+)\)"/, "build(\\1)")
      |> String.replace(~r/"\[build\((.+)\)\]"/, "[build(\\1)]")

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

  defp put_assoc_build(attrs, schema_module, associations) do
    build_fields =
      associations
      |> Enum.map(fn association ->
        apply(schema_module, :__schema__, [:association, association])
      end)
      |> Enum.map(fn %{
                       queryable: queryable,
                       field: field,
                       cardinality: cardinality
                     } ->
        Code.ensure_compiled?(queryable)
        |> case do
          true ->
            factory_name =
              apply(queryable, :__schema__, [:source])
              |> Inflex.singularize()

            {field, build_string(factory_name, cardinality)}

          false ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    Map.merge(attrs, build_fields)
  end

  defp build_string(factory_name, :one) do
    "build(:#{factory_name})"
  end

  defp build_string(factory_name, :many) do
    "[build(:#{factory_name})]"
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
  defp example_val(_, :naive_datetime), do: ~N[2019-01-01 00:00:00]

  defp validate_args([_] = args), do: args

  defp validate_args(_) do
    Mix.raise("""
    Invalid arguments

    mix ex_machina.gen expects schema module name:

      mix ex_machina.gen Blog.Post
    """)
  end
end
