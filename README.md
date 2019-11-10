# ExMachinaGen

ExMachinaGen is additional mix task for ExMachina.

## Installation

```elixir
def deps do
  [
    {:ex_machina_gen, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

And fetch the dependencies.

```
$ mix deps.get
```

## Usage

ExMachinaGen has two mix tasks:

- `ex_machina.init`
- `ex_machina.gen`

### Generate main factory

To generate main factory file, run `ex_machina.init` mix task.

```
$ mix ex_machina.init
```

The main factory file will be generated.

```elixir
# test/support/factory/factory.ex
defmodule MyApp.Factory do
  use ExMachina.Ecto, repo: MyApp.Repo
end
```

### Generate schema factory

To generate factory of schema, `ex_machina.gen <schema module>`.

```
$ mix ex_machina.gen MyApp.Blog.Post
```

This task generate factory module with example values based on filed's type.

For example, if you define schema module like this,
```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    field :draft, :boolean
    belongs_to :author, MyApp.Blog.User

    timestamps(type: :utc_datetime)
  end
  ...
```

the factory module will be generate like this.

```elixir
defmodule MyApp.Blog.PostFactory do
  defmacro __using__(_opts) do
    quote do
      def post_factory do
        %MyApp.Blog.Post{
          author: build(:user),
          body: "test body",
          draft: true,
          inserted_at: ~U[2019-01-01 00:00:00Z],
          title: "test title",
          updated_at: ~U[2019-01-01 00:00:00Z]
        }
      end
    end
  end
end
```

## Configuration

If you change factory directory(default: `test/support/factory`), add `factory_dir` config.

```elixir
config :ex_machina_gen,
  factory_dir: "test/factory"
```
