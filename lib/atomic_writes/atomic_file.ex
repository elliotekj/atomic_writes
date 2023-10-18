defmodule AtomicWrites.AtomicFile do
  @moduledoc """
  Serializes the atomic writes to a file.
  """
  use GenServer

  @doc """
  #{NimbleOptions.docs(AtomicWrites.opts_schema())}
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    case AtomicWrites.validate_opts(opts) do
      {:ok, opts} -> {:ok, AtomicWrites.expand_opts(opts)}
      {:error, %NimbleOptions.ValidationError{} = error} -> {:stop, Exception.message(error)}
    end
  end

  @doc """
  Atomically write to the path.
  """
  @spec write(pid(), iodata()) :: :ok | {:error, atom()}
  def write(pid, content) do
    GenServer.call(pid, {:write, content})
  end

  def handle_call({:write, content}, _from, opts) do
    {:reply, AtomicWrites.write(content, opts), opts}
  end
end
