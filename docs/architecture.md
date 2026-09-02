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
- Cycle-accurate tests for the controller
- Small assembly programs for CPU-level integration

Any behavior not yet backed by a passing test remains a target, not a claimed result.
