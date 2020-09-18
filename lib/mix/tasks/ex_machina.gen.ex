defmodule Mix.Tasks.ExMachina.Gen do
  @shortdoc "Generate factory from Ecto schema module"

  @moduledoc """
  Generate factory from Ecto schema module.

      mix ex_machina.gen Blog.Post

  ## table

  By default the table name, singularized, will be used as the prefix for the
  factory method, and filename. To customize this value, a `--name` option may be provided.

      mix ex_machina.gen --name posting Blog.Post

  ## Custom Ecto types

  When a custom `Ecto` type is used in a schema, the generation will attempt to
  `load` a value of `type`, it this fails a warning will be shown for the field
  and the value in the factory will be set to `nil`.

  """
  use Mix.Task
  alias Mix.ExMachinaGen

  def run(args) do
    Mix.Task.run("loadpaths")
    {opts, parsed} = OptionParser.parse!(args, strict: [name: :string])

    [schema_string] = validate_args(parsed)

    {schema_module, struct_string} = process_schema(schema_string)

    singular =
      Keyword.get(
        opts,
        :name,
        apply(schema_module, :__schema__, [:source]) |> Inflex.singularize()
      )

    module = "#{schema_string}Factory"

    binding = [
      module: module,
      singular: singular,
      struct_string: struct_string
    ]

    factory_file_path = ExMachinaGen.factory_file_path(singular)

    Mix.ExMachinaGen.create_file(
      factory_file_path,
      "priv/templates/ex_machina.gen/factory.ex",
      binding
    )

    inject_use_statement(module)
    Mix.Task.run("format", [factory_file_path])
  end

  defp process_schema(schema_string) do
    schema_module = Module.concat([Elixir, schema_string])

    fields = apply(schema_module, :__schema__, [:fields])

    primary_key =
      apply(schema_module, :__schema__, [:primary_key])
      |> case do
        [] -> nil
        [pk] -> pk
      end

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
      |> cleanup()

    {schema_module, struct_string}
  end

  defp cleanup(str) do
    str
    |> String.replace(~r/"build\(([^\)]+)\)"/, "build(\\1)")
    |> String.replace(~r/"\[build\(([^\)]+)\)\]"/, "[build(\\1)]")
    |> String.replace(~r/"(\[?%\{[^\}]+\}\]?)"/, "\\1")
    |> String.replace(~r/\\/, "")
  end

  defp process_embedded_schema(schema_string) do
    schema_module = Module.concat([Elixir, schema_string])

    fields = apply(schema_module, :__schema__, [:fields])

    associations = apply(schema_module, :__schema__, [:associations])

    assoc_field_keys =
      associations
      |> Enum.map(fn assoc_field ->
        apply(schema_module, :__schema__, [:association, assoc_field])
      end)
      |> Enum.map(fn assoc_struct -> assoc_struct.owner_key end)

    fields
    |> Kernel.--(assoc_field_keys)
    |> to_attrs_map(schema_module)
    |> put_assoc_build(schema_module, associations)
    |> inspect(pretty: true, width: :infinity)
    |> cleanup()
  end

  defp inject_use_statement(module) do
    main_factory_file_path = ExMachinaGen.main_factory_file_path()

    if !File.exists?(main_factory_file_path) do
      Mix.Tasks.ExMachina.Init.run()
    end

    file = File.read!(main_factory_file_path)
    use_statement = "  use #{module}\n"

    if String.contains?(file, use_statement) do
      :ok
    else
      file
      |> String.trim_trailing()
      |> String.trim_trailing("end")
      |> Kernel.<>(use_statement)
      |> Kernel.<>("end\n")
      |> write_file(main_factory_file_path)

      Mix.shell().info([
        :green,
        "* injecting ",
        :reset,
        Path.relative_to_cwd(main_factory_file_path)
      ])
    end
  end

  defp write_file(content, file) do
    File.write!(file, content)
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
        Code.ensure_compiled(queryable)
        |> case do
          {:module, _} ->
            factory_name =
              apply(queryable, :__schema__, [:source])
              |> Inflex.singularize()

            {field, build_string(factory_name, cardinality)}

          {:error, _} ->
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

  defp example_val(_, :id), do: 1
  defp example_val(_, :binary_id), do: nil
  defp example_val(_, :integer), do: 1
  defp example_val(_, :float), do: 1.0
  defp example_val(_, :boolean), do: true
  defp example_val(field, :string), do: "test #{field}"
  defp example_val(_, :binary), do: nil
  defp example_val(field, {:array, type}), do: [example_val(Inflex.singularize(field), type)]
  defp example_val(_, :map), do: %{}
  defp example_val(_, {:map, _}), do: %{}
  defp example_val(_, :decimal), do: Decimal.cast(1)
  defp example_val(_, :date), do: ~D[2019-01-01]
  defp example_val(_, :time), do: ~T[00:00:00]
  defp example_val(_, :time_usec), do: ~T[00:00:00.000000]
  defp example_val(_, :utc_datetime), do: ~U[2019-01-01 00:00:00Z]
  defp example_val(_, :utc_datetime_usec), do: ~U[2019-01-01 00:00:00.000000Z]
  defp example_val(_, :naive_datetime), do: ~N[2019-01-01 00:00:00]
  defp example_val(_, :naive_datetime_usec), do: ~N[2019-01-01 00:00:00.000000]

  defp example_val(_, {:embed, %Ecto.Embedded{cardinality: cardinality, related: schema}}) do
    value = process_embedded_schema(schema)

    case cardinality do
      :one -> value
      _ -> "[" <> value <> "]"
    end
    |> Code.eval_string()
    |> elem(0)
  end

  defp example_val(field, type) when is_atom(type) do
    value = example_val(field, apply(type, :type, []))

    case apply(type, :load, [value]) do
      {:ok, v} ->
        v

      :error ->
        Mix.shell().info([
          :yellow,
          " The value for `:#{field}` could not be autogenerated!"
        ])

        nil
    end
  end

  defp validate_args([_] = args), do: args

  defp validate_args(_) do
    Mix.raise("""
    Invalid arguments

    mix ex_machina.gen expects schema module name:

      mix ex_machina.gen Blog.Post
    """)
  end
end
