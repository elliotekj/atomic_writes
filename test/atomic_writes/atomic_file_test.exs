defmodule AtomicWrites.AtomicFileTest do
  use ExUnit.Case

  alias AtomicWrites.AtomicFile

  @file_path "test_file.txt"

  setup do
    opts = [path: @file_path]
    {:ok, pid} = AtomicFile.start_link(opts)
    on_exit(fn -> File.rm(@file_path) end)

    {:ok, %{pid: pid}}
  end

  describe "write/1" do
    test "writes data to the path atomically", %{pid: pid} do
      content = "Test string."
      :ok = AtomicFile.write(pid, content)

      assert File.exists?(@file_path)
      assert File.read!(@file_path) == content
    end

    test "handles concurrent writes correctly", %{pid: pid} do
      content_1 = "First test string."
      content_2 = "Second test string."

      task_1 = Task.async(fn -> AtomicFile.write(pid, content_1) end)
      task_2 = Task.async(fn -> AtomicFile.write(pid, content_2) end)

      Task.await_many([task_1, task_2])

      # Since writes are serialized, the file should contain `content_2`
      assert File.exists?(@file_path)
      assert File.read!(@file_path) == content_2
    end

    test "no partial write occurs if the process is killed" do
      Process.flag(:trap_exit, true)

      opts = [path: @file_path]
      {:ok, atomic_pid} = AtomicFile.start_link(opts)

      long_content = random_long_multiline()

      task_1 =
        Task.async(fn ->
          try do
            AtomicFile.write(atomic_pid, long_content)
          catch
            _, _ -> :ok
          end
        end)

      task_2 =
        Task.async(fn ->
          # Give time for a partial write to be possible
          Process.sleep(20)
          Process.exit(atomic_pid, :kill)
        end)

      Task.await_many([task_1, task_2])

      if File.exists?(@file_path) do
        # If the file exists, it's because the full write succeeded
        # Therefore we assert that no partial write occured
        assert File.read!(@file_path) == long_content
      end

      Process.flag(:trap_exit, false)
    end

    test "overwrite?=false does not overwrite an existing file" do
      opts = [path: @file_path, overwrite?: false]
      {:ok, pid} = AtomicFile.start_link(opts)

      content_1 = "First test string."
      content_2 = "Second test string."

      assert :ok = AtomicFile.write(pid, content_1)
      assert {:error, :eexist} = AtomicFile.write(pid, content_2)

      assert File.exists?(@file_path)
      assert File.read!(@file_path) == content_1
    end
  end

  defp random_long_multiline, do: Enum.map_join(0..10_000, "\n", fn _ -> random_line() end)
  defp random_line, do: Enum.map_join(1..200, "", fn _ -> random_byte() end)
  defp random_byte, do: <<Enum.random(0..255)>>
end
