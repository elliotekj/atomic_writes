# AtomicWrites: LWW, FWW & Serialized Atomic File Writes in Elixir

Perform last-write-wins, first-write-wins or serialized atomic file writes in
Elixir with **AtomicWrites**. The basic idea is that writes are made to a
temporary file and then moved when the write is complete. By default, the
temporary write is made to the same file system (so that the move is also
atomic) and the move will overwrite any existing file (LWW). Both of these
options are configurable.

## LWW Atomic Writes

```elixir
AtomicWrites.write("Atomically written content.", path: "example.txt")
```

## FWW Atomic Writes

```elixir
AtomicWrites.write("Atomically written content.", path: "example.txt", overwrite?: false)
```

## Serialized Atomic Writes

``` elixir
alias AtomicWrites.AtomicFile

{:ok, pid} = AtomicFile.start_link(path: "example.txt")
AtomicFile.write(pid, "Serialized, atomically written content.")
```

## Installation

The package can be installed by adding `atomic_writes` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:atomic_writes, "~> 1.1"}
  ]
end
```

## Documentation

The documentation is published at <https://hexdocs.pm/atomic_writes>.

## License

AtomicWrites is released under the [`Apache License
2.0`](https://github.com/elliotekj/atomic_writes/blob/main/LICENSE).

## About

This package was written by [Elliot Jackson](https://elliotekj.com).

- Blog: [https://elliotekj.com](https://elliotekj.com)
- Email: elliot@elliotekj.com
