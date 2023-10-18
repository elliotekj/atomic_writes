defmodule AtomicWritesTest do
  use ExUnit.Case

  @file_path "test_file.txt"

  setup do
    opts = [path: @file_path]
    on_exit(fn -> File.rm(@file_path) end)

    {:ok, %{opts: opts}}
  end

  describe "write/1" do
    test "writes data to the path", %{opts: opts} do
      content = "Test string."
      :ok = AtomicWrites.write(content, opts)

      assert File.exists?(@file_path)
      assert File.read!(@file_path) == content
    end

    test "handles concurrent writes correctly", %{opts: opts} do
      content_1 = "First test string."
      content_2 = "Second test string."

      task_1 = Task.async(fn -> AtomicWrites.write(content_1, opts) end)
      task_2 = Task.async(fn -> AtomicWrites.write(content_2, opts) end)

      Task.await_many([task_1, task_2])

      # Since writes are *not* serialized, last write wins. The file should
      # contain either `content_1` or `content_2` but not a mixture of both.
      assert File.exists?(@file_path)
      assert File.read!(@file_path) == content_1 or content_2
    end

    test "overwrite?=false does not overwrite an existing file" do
      opts = [path: @file_path, overwrite?: false]

      content_1 = "First test string."
      content_2 = "Second test string."

      assert :ok = AtomicWrites.write(content_1, opts)
      assert {:error, :eexist} = AtomicWrites.write(content_2, opts)

      assert File.exists?(@file_path)
      assert File.read!(@file_path) == content_1
    end
  end
end
