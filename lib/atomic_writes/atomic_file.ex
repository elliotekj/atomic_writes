defmodule AtomicWrites.AtomicFile do
  @moduledoc """
  Given a file path (and other optional config), `AtomicFile` provides a
  `write/2` method for serially and atomically writing to the given path.
  """
  use GenServer

  @opts_schema NimbleOptions.new!(
                 path: [
                   type: :string,
                   required: true,
                   doc: "Path to the final file that is atomically written."
                 ],
                 overwrite?: [
                   type: :boolean,
                   default: true,
                   doc: "Overwrite the target file if it already exists?"
                 ],
                 tmp_dir: [
                   type: :string,
                   default: ".",
                   doc: "Directory in which the temporary files are written."
                 ]
               )

  @doc """
  #{NimbleOptions.docs(@opts_schema)}
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, config} -> {:ok, config}
      {:error, %NimbleOptions.ValidationError{} = error} -> {:stop, Exception.message(error)}
    end
  end

  @spec write(pid(), iodata()) :: :ok | {:error, atom()}
  @doc """
  Atomically write to the path managed by the process.
  """
  def write(pid, content) do
    GenServer.call(pid, {:write, content})
  end

  def handle_call({:write, content}, _from, config) do
    tmp_dir_path = config[:tmp_dir] |> Path.expand() |> Path.dirname()
    tmp_filename = UUID.uuid4() <> ".atomicwrite"
    tmp_file_path = Path.join([tmp_dir_path, tmp_filename])
    dest_file_path = Path.expand(config[:path])
    dest_dir_path = Path.dirname(dest_file_path)

    with :ok <- File.mkdir_p(tmp_dir_path),
         :ok <- File.mkdir_p(dest_dir_path),
         :ok <- File.write(tmp_file_path, content) do
      result = maybe_move_file(tmp_file_path, dest_file_path, config[:overwrite?])
      Process.send(self(), {:remove, tmp_file_path}, [])
      {:reply, result, config}
    else
      e -> {:reply, e, config}
    end
  end

  def handle_info({:remove, path}, config) do
    File.rm(path)
    {:noreply, config}
  end

  defp maybe_move_file(tmp_file_path, dest_file_path, overwrite?) do
    if File.exists?(dest_file_path) && overwrite? == false do
      {:error, :eexist}
    else
      File.rename(tmp_file_path, dest_file_path)
    end
  end
end
