# Architecture specification

## Purpose

This CPU is intentionally small enough to trace by hand while still demonstrating the essential parts of a microcontroller: a datapath, memory, an instruction set, flags, and a control unit.

## Programmer-visible state

- `A`: 8-bit accumulator
- `PC`: 8-bit program counter
- `Z`: zero flag, set when an ALU result is zero
- `C`: carry flag, used for unsigned arithmetic
- `MEM[0:255]`: unified 8-bit program and data memory

The operand register and instruction register are internal implementation details.

## Instruction encoding

Each opcode is one byte. Instructions marked `operand` consume the following byte as an immediate value or address. This keeps decoding simple and retains the full 8-bit address space.

| Opcode | Mnemonic | Bytes | Operation |
|---:|---|---:|---|
| `00` | `NOP` | 1 | No operation |
| `10` | `LDI operand` | 2 | `A <- operand` |
| `11` | `LDA address` | 2 | `A <- MEM[address]` |
| `12` | `STA address` | 2 | `MEM[address] <- A` |
| `20` | `ADD address` | 2 | `{C,A} <- A + MEM[address]` |
| `21` | `SUB address` | 2 | `A <- A - MEM[address]` |
| `22` | `AND address` | 2 | `A <- A & MEM[address]` |
| `23` | `OR address` | 2 | `A <- A | MEM[address]` |
| `24` | `XOR address` | 2 | `A <- A ^ MEM[address]` |
| `30` | `JMP address` | 2 | `PC <- address` |
| `31` | `JZ address` | 2 | Jump when `Z = 1` |
| `32` | `JC address` | 2 | Jump when `C = 1` |
| `FF` | `HLT` | 1 | Stop instruction execution |

`SUB` will define `C = 1` as “no borrow,” matching the common adder-based implementation `A + ~B + 1`.

## Instruction decoder

The implemented combinational decoder recognizes the 13 opcodes in the table above and exposes four pieces of control information: instruction class, whether a second byte must be fetched, the ALU selector, and a validity flag. Each opcode recognizer is an 8-bit structural equality comparator assembled from XOR, inverter, and AND cells. Their match terms are combined through a balanced OR tree.

All other opcode bytes produce `INSTRUCTION_INVALID`, deassert `has_operand` and `valid`, and select the benign `ALU_PASS_A` operation. This makes every one of the 256 input combinations explicit and prevents a reserved opcode from accidentally requesting an architectural operation. The decoder testbench checks all 256 values and confirms that exactly 13 are valid.

## Arithmetic logic unit

The implemented combinational ALU accepts two 8-bit operands and a 3-bit operation selector.

| Selector | Operation | Result | Carry output |
|---:|---|---|---|
| `000` | ADD | `A + B` | Unsigned carry |
| `001` | SUB | `A + not(B) + 1` | `1` means no borrow |
| `010` | AND | `A and B` | `0` |
| `011` | OR | `A or B` | `0` |
| `100` | XOR | `A xor B` | `0` |
| `101` | PASS A | `A` | `0` |
| `110`, `111` | Reserved | `0` | `0` |

The zero output is `1` whenever the selected 8-bit result is `00`. Addition and subtraction share the structural ripple-carry adder: every B bit passes through an XOR controlled by the subtraction selector, and that selector also becomes the adder carry-in. The logic functions are generated from the reusable structural gate entities.

## Clocked datapath state

The implemented `register8` block is the reusable storage primitive for the accumulator, operand register, and instruction register. It has synchronous active-high reset and load-enable inputs. At each rising clock edge, reset clears the register, load-enable captures the input, and otherwise the stored value is held.

The implemented `program_counter8` supports four behaviors with an explicit priority:

1. Reset to `00`.
2. Parallel-load a branch or jump address.
3. Increment after an instruction or operand fetch.
4. Hold the current address.

Incrementing reuses the structural ripple-carry adder by adding a carry-in of one to an all-zero second operand. Overflow intentionally wraps `FF` to `00`, matching the 256-byte address space. Both blocks use synchronous control so their state changes only on rising clock edges.

## Internal data bus

The implemented internal bus is an 8-bit combinational source selector. A 3-bit control field selects one of the datapath values:

| Selector | Bus source |
|---:|---|
| `000` | Accumulator |
| `001` | Operand register |
| `010` | Instruction register |
| `011` | Program counter |
| `100` | Memory read data |
| `101` | ALU result |
| `110`, `111` | Constant zero |

A discrete processor can use tri-state output drivers so that one component drives a shared physical wire at a time. Internal tri-state nets are generally not present in modern FPGA routing fabric, so this design uses a structural multiplexer tree instead. Eight copies of a gate-built 2:1 multiplexer form each selection level. This maps predictably to FPGA logic and makes invalid selector codes produce zero rather than contention or an unknown value.

## Unified structural memory

The implemented memory contains 256 addressable bytes. Each byte is an explicit clocked storage element, each write enable is formed by an 8-bit structural address comparator, and the read path is a balanced eight-level tree of gate-built 2:1 multiplexers. Reads are combinational; writes occur on the rising clock edge. Synchronous reset has priority over writes and reloads the configured initial image.

This organization is deliberately structural and inspectable, but synthesis will use approximately 2,048 flip-flops plus decoder and multiplexer logic rather than infer an FPGA block RAM. A later board-specific implementation can replace it with an inferred or vendor RAM without changing the CPU-facing interface. No block-RAM utilization or hardware timing result is claimed for this milestone.

The default image contains this reference program:

| Address | Bytes | Instruction | Purpose |
|---:|---|---|---|
| `00` | `10 05` | `LDI 05` | Load 5 into A |
| `02` | `12 F0` | `STA F0` | Store 5 at data address F0 |
| `04` | `11 F0` | `LDA F0` | Load the stored value |
| `06` | `20 F0` | `ADD F0` | Add 5, producing A = 10 |
| `08` | `12 F1` | `STA F1` | Store the result at F1 |
| `0A` | `FF` | `HLT` | Stop execution |

The complete CPU integration test now verifies that execution leaves `MEM[F0] = 05` and `MEM[F1] = 0A`.

## Multi-cycle control unit

The implemented controller uses the existing synchronous `register8` as a three-bit state register, with a separate combinational next-state and output network. The six defined states are:

1. **Fetch**: read `MEM[PC]` into the instruction register and increment `PC`.
2. **Decode**: validate the instruction and choose whether an operand byte is required.
3. **Operand fetch**: read `MEM[PC]` into the operand register and increment `PC`.
4. **Execute**: issue the bus, register, memory, flag, and PC control signals for the decoded instruction.
5. **Halted**: hold all write controls inactive after `HLT` until reset.
6. **Fault**: hold all write controls inactive after an invalid opcode or unused state encoding until reset.

The unified memory is assumed to have a combinational read port. `address_from_operand = 0` selects `PC` for instruction and operand fetches; `address_from_operand = 1` selects the operand register for `LDA`, `STA`, and ALU memory accesses. Only ALU instructions assert `flags_load`. `JZ` and `JC` test the stored flags and assert `pc_load` only when their condition is true. The cycle-accurate testbench checks every instruction class, taken and non-taken conditional branches, both lock states, and reset recovery.

## Complete CPU integration

The implemented `cpu8` entity structurally connects the instruction and operand registers, accumulator, program counter, flag register, instruction decoder, multi-cycle controller, ALU, internal bus, memory-address multiplexers, and unified memory. ALU operand A comes from the accumulator and operand B comes from `MEM[operand]`. The decoder's ALU selector and instruction classification feed the controller and datapath directly.

The two stored flags occupy the low bits of an existing eight-bit register: bit 0 is carry and bit 1 is zero. They update only when the controller asserts `flags_load`. Memory addresses normally select either PC or the operand register. A separate verification/debug address can override that selection, and a structural interlock disables memory writes whenever debug access is active.

The end-to-end test resets the CPU, releases it, and lets the default reference program run without testbench intervention. The CPU reaches `HLT` after exactly 23 rising edges with `PC = 0B`, `A = 0A`, `MEM[F0] = 05`, and `MEM[F1] = 0A`. It also verifies that program bytes were not modified and that reset recovers from halt and reloads the initial memory image. These are simulation results; FPGA timing and physical-board operation are not yet claimed.

## Memory-mapped GPIO output

Address `FE` is reserved for an eight-bit output register. The port uses the same
structural equality comparator as the memory decoder, combines the address match
with the CPU write strobe through an AND gate, and stores output data in the reusable
eight-bit register. `STA FE` therefore copies the accumulator to the GPIO outputs.
Reset clears all eight outputs to zero.

The GPIO address is removed from ordinary RAM writes. On reads, eight structural
2:1 multiplexers select the GPIO register instead of the underlying RAM byte, so
`LDA FE` reads back the last output value. Debug reads at `FE` see the same mapped
register. All other addresses retain the original unified-memory behavior.

The FPGA demonstration image is separate from the CPU reference program:

| Address | Bytes | Instruction | Purpose |
|---:|---|---|---|
| `00` | `10 A5` | `LDI A5` | Load the visible test pattern |
| `02` | `12 FE` | `STA FE` | Drive `A5` onto the GPIO output |
| `04` | `10 00` | `LDI 00` | Clear A before the readback check |
| `06` | `11 FE` | `LDA FE` | Read the output register back into A |
| `08` | `FF` | `HLT` | Stop with A and GPIO both equal to `A5` |

The standalone peripheral test checks all 256 addresses as well as disabled writes,
hold behavior, and reset. The integrated wrapper test verifies the program reaches
halt in 19 enabled CPU steps with `A = A5`, `GPIO = A5`, and `PC = 09`.

## Vendor-neutral FPGA wrapper

The implemented `fpga_demo_top` keeps every sequential CPU element in the board's
system-clock domain. A configurable counter produces a one-clock-wide enable pulse;
that pulse gates the controller state register and every CPU write, load, and
program-counter control. The default interval is 50,000,000 system-clock cycles.
Its visible step rate therefore depends on the oscillator frequency of the selected
board. This clock-enable scheme avoids routing a logic-generated clock through the
FPGA fabric.

The external active-high reset asserts internally without waiting for a clock edge.
A two-stage synchronizer then deasserts it on the second rising system-clock edge,
so all synchronous CPU state is released together. Reset retains priority over the
clock enable, allowing a paused or halted CPU to recover.

The wrapper exposes the accumulator, program counter, memory-mapped GPIO register,
three-bit controller state, zero and carry flags, halt status, and fault status as
LED/debug ports. It also exports the enable pulse and synchronized reset for
verification or optional debug headers. Its self-checking test uses a short divider,
verifies reset timing, and runs the separate FPGA demonstration image described
above.

This top level is vendor-neutral. It has no pin assignments, oscillator timing
constraint, voltage standard, or device selection because no target board has been
chosen. Consequently, synthesis timing closure and operation on physical hardware
are not claimed. A board-specific constraints file and hardware demonstration remain
the next milestone.

## Abstraction boundary

The `transistor_model/` modules express the truth-table behavior of CMOS pull-up and pull-down networks in VHDL. The accompanying CMOS documentation explains the transistor arrangement. FPGA synthesis starts at `rtl/logic/`, where equivalent cells are expressed as synthesizable structural VHDL-2008. Tests compare behavior at both levels; they do not imply that an FPGA contains discrete CMOS transistors matching the educational model.

## Verification strategy

- Truth-table checks for primitive cells
- Exhaustive arithmetic tests for small datapath blocks
- Exhaustive ALU result and flag tests
- Exhaustive instruction decoding across all opcode bytes
- Cycle-accurate tests for the controller
- Exhaustive address tests for memory writes, reads, retention, and reset loading
- End-to-end reference-program execution with architectural-state checks
- Exhaustive memory-mapped GPIO decoding and register checks
- Clock-enable, reset-conditioning, and wrapper-level demonstration-program checks

Any behavior not yet backed by a passing test remains a target, not a claimed result.
