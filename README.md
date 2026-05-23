# m_fifo — Synchronous FIFO in Verilog

A parameterizable synchronous FIFO built from `m_ff` flip-flop primitives and guarded by `m_assert` simulation checkers. Every storage element — pointers, flags, count, and the data array itself — is an explicit `m_ff` instance: no implicit `always @` blocks, no inferred registers.

> Part of Roy Ayalon's Verilog learning project — designed and reviewed alongside a 34-year Verilog veteran.

---

## Features

- **Configurable** `WIDTH`, `DEPTH`, and `RESET_VAL`
- **Arbitrary depth** — not restricted to powers of two (pointer wrap is explicit, not a free counter overflow)
- **Registered status flags** — `full`, `empty`, and `count` are all flip-flops, not combinational decodes of the pointers
- **Built-in protection assertions**
  - `POP ON EMPTY!` — fires on illegal read
  - `PUSH ON FULL!` — fires on illegal write
- **Simulation-only checks** are wrapped in `// synopsys translate_off` / `translate_on` and stripped by synthesis tools

---

## Block diagram

```
                push ──┐                                 ┌── pop
                       ▼                                 ▼
                ┌──────────┐                       ┌──────────┐
                │write_ptr │                       │ read_ptr │
                │  (FF)    │                       │   (FF)   │
                └────┬─────┘                       └─────┬────┘
                     │                                   │
                     ▼                                   ▼
        ┌───────────────────────────────────────────────────────┐
        │            FIFO storage — DEPTH × m_ff                │
        │   [0] ── [1] ── [2] ── ... ── [DEPTH-1]               │
        │   one m_ff per slot, write-enabled by                 │
        │   (push & write_ptr == i)                             │
        └─────────────────────┬─────────────────────────────────┘
                              │ fifo[read_ptr]
                              ▼
                          data_out
                              
   Status flags (all registered m_ff instances):
   ┌──────┐   ┌───────┐   ┌───────┐
   │ full │   │ empty │   │ count │
   └──────┘   └───────┘   └───────┘
```

---

## Parameters

| Name        | Default | Description                                     |
|-------------|---------|-------------------------------------------------|
| `WIDTH`     | 8       | Bit-width of each FIFO entry                    |
| `DEPTH`     | 9       | Number of FIFO entries                          |
| `RESET_VAL` | 0       | Reset value applied to every storage flip-flop  |

Two `localparam`s are derived from the above:
- `L2DEPTH   = $clog2(DEPTH)`   — pointer width
- `L2DEPTHP1 = $clog2(DEPTH+1)` — `count` width (needs one extra value for "full")

---

## Ports

| Name      | Direction | Width           | Description                                                  |
|-----------|-----------|-----------------|--------------------------------------------------------------|
| `clk`     | input     | 1               | Clock                                                        |
| `rst_n`   | input     | 1               | Active-low asynchronous reset                                |
| `push`    | input     | 1               | Write data_in into the FIFO on next clock edge               |
| `pop`     | input     | 1               | Advance read pointer on next clock edge                      |
| `data_in` | input     | `WIDTH`         | Data to be pushed                                            |
| `data_out`| output    | `WIDTH`         | Current head of the FIFO (combinational — `fifo[read_ptr]`)  |
| `empty`   | output    | 1               | Registered — high when FIFO contains zero elements           |
| `full`    | output    | 1               | Registered — high when FIFO contains `DEPTH` elements        |
| `count`   | output    | `L2DEPTHP1`     | Registered — number of elements currently stored             |

---

## Internal architecture

Every signal that needs to persist across a clock edge is built from an `m_ff` instance:

| Sub-block       | Storage         | Enable                                       | Next-state                                      |
|-----------------|-----------------|----------------------------------------------|-------------------------------------------------|
| `read_ptr`      | `L2DEPTH`-bit FF| `pop`                                        | wrap from `DEPTH-1` → 0, else `+1`              |
| `write_ptr`     | `L2DEPTH`-bit FF| `push`                                       | wrap from `DEPTH-1` → 0, else `+1`              |
| FIFO storage    | `DEPTH` × `m_ff`| `push & (write_ptr == i)`                    | `data_in`                                       |
| `full`          | 1-bit FF        | `pop \| (push & ~pop & count == DEPTH-1)`    | `pop ? 0 : 1`                                   |
| `empty`         | 1-bit FF        | `push \| (pop & ~push & count == 1) \| count==0` | `push ? 0 : 1`                              |
| `count`         | `L2DEPTHP1`-bit FF | `push \| pop`                             | `count + push - pop`                            |

Two key design choices worth calling out:

1. **`full` and `empty` are flip-flops, not derived combinationally from pointer equality.** They are updated by explicit set / reset events. This avoids glitches on the flags, gives a clean single-cycle "becomes full" / "becomes empty" semantic, and matches the [project coding style](../.claude/context/coding-style.md): every status output is a deliberate FF, not an inferred latch.
2. **Pointer wrap is explicit (`== DEPTH-1 ? 0 : +1`)**, so `DEPTH` can be any value — not just a power of two — without aliasing the wrap into a free counter overflow.

---

## Protection assertions

Wrapped in `synopsys translate_off` so they survive simulation but disappear in synthesis:

```verilog
m_assert #(.MESSAGE("POP ON EMPTY!"))   ... .expr(empty & pop);
m_assert #(.MESSAGE("PUSH ON FULL!"))   ... .expr(full  & push);
```

If either condition occurs in simulation, the assertion fires `$stop` with the message — converting silent data corruption into a loud, named failure.

---

## Running the simulation

Use the `scripts/run.sh` helper from anywhere:

```sh
./scripts/run.sh             # compile + run
./scripts/run.sh --gtk       # compile + run + open GTKWave
./scripts/run.sh --clean     # wipe sim/ then rebuild
./scripts/run.sh --help      # usage
```

The script expects sibling repos `m-ff/` and `m-assert/` to be checked out next to `m-fifo/` in a shared parent directory.

If you'd rather invoke `iverilog` directly:

```sh
iverilog -g2012 -o sim/simv \
    ../m-ff/m_ff.v ../m-assert/m_assert.v \
    rtl/m_fifo.v tb/fifo_tb.v && \
    ( cd sim && vvp simv )
```

The `-g2012` flag enables SystemVerilog literals (`'0`) used inside the module. Waveforms land in `sim/tb.vcd`.

---

## Testbench summary

[tb/fifo_tb.v](tb/fifo_tb.v) is a self-checking testbench built in the same style as father's UART TB ([m-UART/tb/tb_uart.v](../m-UART/tb/tb_uart.v)). It instantiates the FIFO with `WIDTH=8`, `DEPTH=4` and runs four sub-tests against a software scoreboard queue:

| #  | Test                                                              | What it verifies                                |
|----|-------------------------------------------------------------------|-------------------------------------------------|
| T1 | Push 3 bytes (`0x06, 0x2A, 0x17`), then pop 3                     | FIFO ordering — first-in is first-out           |
| T2 | Push 4 bytes to fill `DEPTH`                                      | `full` rises on the filling push                |
| T3 | Pop 4 bytes to drain                                              | `empty` rises on the draining pop               |
| T4 | Interleaved push/pop sequence that forces a pointer wrap          | Read/write pointers wrap from `DEPTH-1` to `0`  |

Each `t_push` records the data into a scoreboard array; each `t_pop` reads the next expected value and compares against `data_out`. The TB ends with one of three ASCII banners:

- **`UVM TEST PASSED`** — every popped byte matched the scoreboard
- **`UVM TEST FAILED`** — a data mismatch, a push-on-full, or a pop-on-empty was driven
- **`UVM TEST ERROR`** — the watchdog fired (`SIM_LENGTH = 20000` time units)

Every `@(posedge clk)` in a driver task is followed by `#1` before any stimulus assignment to avoid the active-region race on iverilog (see lesson #4 in `.claude/context/lessons-learned.md`).

---

## File layout

```
m-fifo/
├── rtl/           # synthesizable RTL
│   └── m_fifo.v
├── tb/            # testbenches
│   └── fifo_tb.v
├── sim/           # simv binary + *.vcd outputs (gitignored)
├── scripts/       # run.sh — compile + run + optional GTKWave
│   └── run.sh
├── waves/         # GTKWave save files (*.gtkw)
├── spec/          # spec / requirement docs
├── README.md
└── animation_prompt.md
```

Depends on sibling modules (expected as siblings of `m-fifo/` in the parent directory):
- [`m-ff/m_ff.v`](../m-ff/m_ff.v) — the universal flip-flop primitive
- [`m-assert/m_assert.v`](../m-assert/m_assert.v) — simulation-only checker

---

## Author

**Roy Ayalon** — Electrical Engineering graduate, learning Verilog through father-son design reviews.
