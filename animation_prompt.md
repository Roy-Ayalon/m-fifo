# Animation Prompt — m_fifo for LinkedIn

A ready-to-paste prompt for generating a short technical animation of the `m_fifo` module. Tested phrasing for tools like **Manim, Motion Canvas, After Effects, Runway, Sora, Kling, or a custom JS/Canvas animator**.

Use the **"Master Prompt"** below as-is. The sections after it (style guide, scene breakdown, signal table) are there in case the tool needs more structure or you want to extend the clip.

---

## Master prompt (copy-paste this)

> Create a clean, technical, ~30-second silent animation explaining how a **synchronous FIFO** (First-In-First-Out memory buffer) works, designed in Verilog. The animation will be posted on LinkedIn by a junior digital-design engineer (Roy Ayalon) showcasing his hardware design project.
>
> **Visual style:** minimalist engineering aesthetic. Dark navy background (#0d1b2a). Monospace font (JetBrains Mono or Fira Code). Accent colors: cyan (#00d9ff) for data, green (#00ff88) for active signals, red (#ff3860) for full/error, amber (#ffb000) for empty. Smooth easing on every move. No clutter, no excessive labels, no stock-clip vibes — this should look like a hardware-textbook figure that came alive.
>
> **Subject:** a 4-deep FIFO with 8-bit entries. Render the FIFO as a horizontal row of 4 boxes labeled `[0] [1] [2] [3]`. Above the boxes show two animated pointer arrows: a **green `write_ptr`** above and a **cyan `read_ptr`** below. On the right side show three live status indicators in a vertical stack: `count`, `empty`, `full`.
>
> **Scene 1 — Reset (0:00–0:03).**
> All four FIFO cells empty. `read_ptr = 0`, `write_ptr = 0`. `empty = 1` (amber glow), `full = 0`, `count = 0`. Caption fades in at the top: *"m_fifo — synchronous FIFO in Verilog"*.
>
> **Scene 2 — Push (0:03–0:11).**
> Caption: *"PUSH: write data into the buffer"*. On each clock tick (~0.8 s apart), a new data byte slides into the cell pointed to by `write_ptr`, then `write_ptr` advances by one with a small forward hop. Push the sequence `0x06, 0x2A, 0x17, 0x24`. After each push: `count` increments, `empty` turns off after the first push, `full` turns on (red glow + soft pulse) after the fourth push. When full, draw a brief red outline around the entire FIFO.
>
> **Scene 3 — Pop (0:11–0:19).**
> Caption: *"POP: read data out — oldest first"*. On each clock tick, the cell pointed to by `read_ptr` highlights cyan, its value floats out to the right labeled `data_out`, then `read_ptr` advances by one. Pop in order: `0x06`, then `0x2A`. After each pop: `count` decrements, `full` turns off after the first pop. Emphasize the **First-In-First-Out** ordering — the first byte pushed (0x06) is the first byte popped.
>
> **Scene 4 — Circular wrap (0:19–0:25).**
> Caption: *"Pointers wrap around — circular buffer"*. Push two more bytes (`0x99`, `0xC3`). Show `write_ptr` reaching `[3]`, then wrapping back to `[0]` with a curved arrow animation. Make the wrap moment obvious — slight slow-down, a brief flash on the wrap arrow.
>
> **Scene 5 — Closing card (0:25–0:30).**
> Fade everything to the side. Center text:
> ```
> m_fifo.v
> Parameterizable. Synthesizable.
> Built from m_ff flip-flops.
> Roy Ayalon · Verilog Design
> ```
>
> **Audio:** none. Pure visual. (LinkedIn autoplays muted.)
>
> **Aspect ratio:** 1:1 square (1080×1080) — best for LinkedIn feed engagement.
>
> **Pacing:** crisp, deliberate, every clock tick clearly visible. No motion blur. Each state change should feel like a hardware step, not a UI animation.

---

## Optional add-ons (paste if the tool allows scene-level direction)

### Style guide

- **Background:** solid `#0d1b2a` (dark navy)
- **Grid:** subtle 1-px cyan grid at 5% opacity, behind everything
- **Font:** JetBrains Mono Bold for labels, JetBrains Mono Regular for values
- **Data byte display:** hex format with `0x` prefix
- **Pointer arrows:** triangular arrowhead, 24-pt, with a thin trailing line connecting to the cell
- **Cell:** 80×80 px rounded rectangle, 2-px border, hex value centered, value-on-empty = dim gray placeholder `--`
- **Transitions:** 200 ms ease-out for pointer movement; 100 ms snap for value updates
- **Status indicators:**
  - `count` — large numeric display
  - `empty` — small LED-style dot; amber when 1, gray when 0
  - `full`  — small LED-style dot; red when 1, gray when 0

### Signal sequence (cycle-accurate, mirrors testbench behavior)

| Cycle | push | pop | data_in | write_ptr | read_ptr | count | empty | full | data_out |
|-------|------|-----|---------|-----------|----------|-------|-------|------|----------|
| 0     | 0    | 0   | --      | 0         | 0        | 0     | 1     | 0    | --       |
| 1     | 1    | 0   | 0x06    | 0         | 0        | 0     | 1     | 0    | --       |
| 2     | 1    | 0   | 0x2A    | 1         | 0        | 1     | 0     | 0    | 0x06     |
| 3     | 1    | 0   | 0x17    | 2         | 0        | 2     | 0     | 0    | 0x06     |
| 4     | 1    | 0   | 0x24    | 3         | 0        | 3     | 0     | 0    | 0x06     |
| 5     | 0    | 0   | --      | 0 (wrap)  | 0        | 4     | 0     | 1    | 0x06     |
| 6     | 0    | 1   | --      | 0         | 0        | 4     | 0     | 1    | 0x06     |
| 7     | 0    | 1   | --      | 0         | 1        | 3     | 0     | 0    | 0x2A     |
| 8     | 0    | 0   | --      | 0         | 2        | 2     | 0     | 0    | 0x17     |

Use this table to drive the animation frame-by-frame if the tool supports keyframe data.

### LinkedIn caption draft (to go with the video)

> Spent the last few weeks designing and verifying a synchronous FIFO from scratch in Verilog 👇
>
> Every storage element — pointers, flags, the data array — is an explicit flip-flop primitive (`m_ff`). No inferred registers, no implicit `always` blocks. Protection assertions (`PUSH ON FULL`, `POP ON EMPTY`) catch silent data corruption in simulation.
>
> What I love about hardware: the abstraction never lies. You can watch the bytes physically move through the buffer, see the pointers wrap around, see `full` rise the exact cycle the last slot fills.
>
> Code + docs on my GitHub. Designed alongside my father — 34 years of Verilog experience — who reviews every line.
>
> #Verilog #DigitalDesign #FPGA #HardwareEngineering #RTL

---

## Tips per tool

- **Manim (Python):** ask the model to output Manim Community Edition code. Use `Square`, `Arrow`, `Tex`, and `MoveAlongPath` for pointer movement. Add `self.wait(0.8)` between cycles.
- **Motion Canvas (TS):** great for cycle-accurate engineering animations. Ask for `signal()` references for each register.
- **Sora / Runway / Kling (video AI):** paste only the Master Prompt above. Skip the cycle table — these tools handle narrative pacing, not frame data. Specify "no audio" and "1:1 square."
- **After Effects:** the Master Prompt works as a brief; the scene breakdown is the storyboard.
- **Custom JS/Canvas:** feed the signal table directly as JSON.
