# https://github.com/adobe/elixir-styler/issues/43#issuecomment-1555951813
opts_schema =
  NimbleOptions.new!(
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

defmodule AtomicWrites do
  @moduledoc """
  Perform serialized and atomic file writes in Elixir with **AtomicWrites**. The
  basic idea is that writes are made to a temporary file and then moved when the
  write is complete. By default, the temporary write is made to the same file
  system (so that the move is also atomic) and the move will overwrite any
  existing file. Both of these options are configurable.


  ## Example

  ``` elixir
  alias AtomicWrites.AtomicFile

  {:ok, pid} = AtomicFile.start_link([path: "example.txt"])
  AtomicFile.write(pid, "Atomically written content.")
  ```

  ## Installation

  The package can be installed by adding `atomic_writes` to your list of
  dependencies in `mix.exs`:

  ```elixir
  def deps do
  [
    {:atomic_writes, "~> 1.0.0"}
  ]
  end
  ```

  ## Documentation

  Please find the documentation under `AtomicWrites.AtomicFile`.

  ## License

  AtomicWrites is released under the [`Apache License
  2.0`](https://github.com/elliotekj/atomic_writes/blob/main/LICENSE).

  ## About

  This package was written by [Elliot Jackson](https://elliotekj.com).

  - Blog: [https://elliotekj.com](https://elliotekj.com)
  - Email: elliot@elliotekj.com
  """

  @opts_schema opts_schema

  @doc """
  Atomically write to the path.
  """
  @spec write(iodata(), Keyword.t()) :: :ok | {:error, atom()}
  def write(content, opts) do
    with {:ok, opts} <- validate_opts(opts),
         opts <- expand_opts(opts),
         {:ok, tmp_file_path} <- preflight(opts),
         :ok <- File.write(tmp_file_path, content) do
      result = maybe_move_file(tmp_file_path, opts[:path], opts[:overwrite?])
      spawn(fn -> File.rm(tmp_file_path) end)
      result
    else
      e -> e
    end
  end

  @doc false
  def opts_schema, do: @opts_schema

  @doc false
  def validate_opts(opts) do
    case Keyword.get(opts, :valid?) == true do
      true -> {:ok, opts}
      false -> NimbleOptions.validate(opts, @opts_schema)
    end
  end

  @doc false
  def expand_opts(opts) do
    opts
    |> Keyword.put(:valid?, true)
    |> Keyword.put(:tmp_dir, Path.expand(opts[:tmp_dir]))
    |> Keyword.put(:path, Path.expand(opts[:path]))
  end

  defp uniq_filename, do: UUID.uuid4() <> ".atomicwrite"

  defp preflight(opts) do
    tmp_filename = uniq_filename()
    tmp_file_path = Path.join([opts[:tmp_dir], tmp_filename])
    dest_dir_path = Path.dirname(opts[:path])

    with :ok <- File.mkdir_p(opts[:tmp_dir]),
         :ok <- File.mkdir_p(dest_dir_path) do
      {:ok, tmp_file_path}
    else
      e -> e
    end
  end

  defp maybe_move_file(tmp_file_path, dest_file_path, overwrite?) do
    case File.exists?(dest_file_path) && overwrite? == false do
      true -> {:error, :eexist}
      false -> File.rename(tmp_file_path, dest_file_path)
    end
  end
end
