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

## Planned microarchitecture

The CPU uses a multi-cycle state machine so that a small amount of hardware can be reused:

1. **Fetch**: read `MEM[PC]` into the instruction register and increment `PC`.
2. **Operand fetch**: for a two-byte instruction, read `MEM[PC]` into the operand register and increment `PC`.
3. **Execute**: select the ALU or memory operation, update state, then return to fetch.

## Abstraction boundary

The `transistor_model/` modules express the truth-table behavior of CMOS pull-up and pull-down networks in VHDL. The accompanying CMOS documentation explains the transistor arrangement. FPGA synthesis starts at `rtl/logic/`, where equivalent cells are expressed as synthesizable structural VHDL-2008. Tests compare behavior at both levels; they do not imply that an FPGA contains discrete CMOS transistors matching the educational model.

## Verification strategy

- Truth-table checks for primitive cells
- Exhaustive arithmetic tests for small datapath blocks
- Exhaustive ALU result and flag tests
- Exhaustive instruction decoding across all opcode bytes
- Cycle-accurate tests for the controller
- Small assembly programs for CPU-level integration

Any behavior not yet backed by a passing test remains a target, not a claimed result.
