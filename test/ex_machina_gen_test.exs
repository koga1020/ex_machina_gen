defmodule ExMachinaGenTest do
  use ExUnit.Case

  @test_tmp_dir "tmp/"
  setup do
    Application.put_env(:ex_machina_gen, :factory_dir, @test_tmp_dir)
    File.mkdir_p!(@test_tmp_dir)

    on_exit(fn ->
      File.rm_rf!(@test_tmp_dir)
    end)

    :ok
  end

  defmodule Blog.User do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Blog.Post do
    use Ecto.Schema

    schema "posts" do
      field(:title, :string)
      field(:body, :string)
      field(:is_draft, :boolean)
      field(:tags, {:array, :string})
      field(:meta, :map)
      field(:order, :integer)
      belongs_to(:user, Blog.User)
      timestamps()
    end
  end

  describe "ex_machina.init" do
    test "generate main factory file(with ecto)" do
      Mix.Tasks.ExMachina.Init.run([])
      main_factory_file = Path.join([@test_tmp_dir, "factory.ex"])
      assert File.exists?(main_factory_file) == true

      file = File.read!(main_factory_file)

      assert file =~ "defmodule ExMachinaGen.Factory do"
      assert file =~ "use ExMachina.Ecto, repo: ExMachinaGen.Repo"
    end

    test "generate main factory file(without ecto)" do
      Mix.Tasks.ExMachina.Init.run(["--no-ecto"])
      main_factory_file = Path.join([@test_tmp_dir, "factory.ex"])
      assert File.exists?(main_factory_file) == true

      file = File.read!(main_factory_file)

      assert file =~ "defmodule ExMachinaGen.Factory do"
      assert file =~ "use ExMachina"
    end
  end

  describe "ex_machina.gen" do
    test "generate factory file" do
      Mix.Tasks.ExMachina.Gen.run(["ExMachinaGenTest.Blog.Post"])
      main_factory_file = Path.join([@test_tmp_dir, "post_factory.ex"])
      assert File.exists?(main_factory_file) == true

      file = File.read!(main_factory_file)

      assert file =~ "defmodule ExMachinaGenTest.Blog.PostFactory do"
      assert file =~ "defmacro __using__(_opts) do"
      assert file =~ "quote do"
      assert file =~ "def post_factory do"
      assert file =~ ~s(%ExMachinaGenTest.Blog.Post{)
      assert file =~ ~s(title: "test title")
      assert file =~ ~s(body: "test body")
      assert file =~ ~s(is_draft: true)
      assert file =~ ~s(tags: ["test tag"])
      assert file =~ ~s(meta: %{})
      assert file =~ ~s(order: 1)
      assert file =~ ~s(inserted_at: ~N[2019-01-01 00:00:00])
      assert file =~ ~s(updated_at: ~N[2019-01-01 00:00:00])
      assert file =~ ~s/user: build(:user)/
    end
  end
end
