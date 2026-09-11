# Transistor-to-FPGA 8-bit Microcontroller

An educational 8-bit microcontroller built from the bottom up. The project connects two views of digital hardware:

1. **CMOS logic models in VHDL** show the Boolean behavior produced by NMOS and PMOS pull-up/pull-down networks.
2. **Synthesizable structural VHDL-2008** composes equivalent gates into datapath blocks that can be implemented on an FPGA.

> FPGA tools cannot map individual NMOS/PMOS devices. The `transistor_model/` tree records the transistor-network behavior in VHDL for learning, while `rtl/` contains the structural VHDL used for synthesis. The physical pull-up/pull-down arrangements are documented in [docs/cmos-foundations.md](docs/cmos-foundations.md).

## Current milestone

Milestone 9 adds a vendor-neutral FPGA demonstration wrapper around the complete
structural CPU:

- CMOS inverter, NAND, and NOR behavior models in VHDL
- synthesizable AND, OR, XOR, and NOT cells
- structural 1-bit full adder
- structural 8-bit ripple-carry adder
- exhaustive adder verification across all 131,072 input combinations
- structural ADD, SUB, AND, OR, XOR, and pass-through ALU operations
- zero and carry/no-borrow flag generation
- exhaustive ALU verification across all 524,288 input combinations
- reusable synchronous 8-bit register with load-enable and hold behavior
- structural 8-bit program counter with parallel load, increment, hold, and wraparound
- verified reset and control-priority behavior for both sequential blocks
- structural 2:1 multiplexer assembled from the reusable gate cells
- 8-bit internal bus selecting accumulator, operand, instruction, PC, memory, or ALU data
- deterministic zero output for both reserved selector codes
- verification of every selector and 2,048 varied full-byte bus cases
- gate-composed equality comparators for all 13 defined opcodes
- deterministic instruction class, operand-length, validity, and ALU-control outputs
- exhaustive verification of all 256 possible opcode bytes
- fetch, decode, operand-fetch, and execute sequencing from a clocked state register
- datapath control strobes for register, flag, PC, bus, and memory operations
- persistent halt and invalid-instruction fault states that require reset
- cycle-accurate verification of every instruction class and both branch outcomes
- 256 bytes of reset-loadable storage with synchronous decoded writes
- balanced eight-level structural multiplexer for combinational reads
- reference program that exercises immediate, load, store, addition, and halt
- exhaustive write, read, retention, and reset-image verification at every address
- structural integration of the datapath, decoder, controller, ALU, flags, PC, and memory
- safe read-only memory debug access with writes inhibited during inspection
- end-to-end execution of the reference program in exactly 23 clock cycles
- verified final state: accumulator `0A`, `MEM[F0] = 05`, and `MEM[F1] = 0A`
- a system-clock enable pulse that slows the CPU without creating a derived clock
- asynchronous reset assertion with two-edge synchronized release
- LED/debug outputs for the accumulator, PC, control state, flags, halt, and fault
- wrapper-level verification of the reference program in exactly 23 CPU steps
- automated GitHub Actions simulation with GHDL

## Target architecture

The planned CPU is a small accumulator machine intended for transparent implementation and step-by-step verification.

| Feature | Target |
|---|---|
| Data width | 8 bits |
| Address width | 8 bits (256-byte address space) |
| Main registers | Accumulator, operand register, instruction register, program counter |
| Flags | Zero and carry |
| Execution | Multi-cycle fetch/decode/execute controller |
| Memory model | Unified program and data memory |
| FPGA interface | System clock, reset button, and LED/debug outputs |

The first instruction set and cycle-level behavior are documented in [docs/architecture.md](docs/architecture.md).

## Repository layout

```text
transistor_model/  Educational VHDL models of CMOS-cell behavior
rtl/logic/         Synthesizable structural VHDL logic and arithmetic
rtl/datapath/      Clocked registers and processor datapath blocks
rtl/control/       Synthesizable instruction decoding and control logic
rtl/memory/        Structural unified memory and program images
rtl/cpu/           Complete processor integration
rtl/fpga/          Vendor-neutral clock, reset, and demonstration wrapper
tb/                Self-checking simulations
docs/              Architecture and design decisions
.github/workflows/ Continuous verification
```

## Run the tests

Install GHDL, then run:

```bash
make test
```

The testbenches stop with a non-zero exit code on the first mismatch, making them suitable for local development and CI.

## Roadmap

- [x] Establish transistor-model and synthesizable-RTL boundaries
- [x] Verify basic CMOS cells and an 8-bit ripple-carry adder
- [x] Build the 8-bit ALU and flags
- [x] Add registers and program counter
- [x] Add the internal bus and datapath selection
- [x] Implement the exhaustive instruction decoder
- [x] Implement the multi-cycle control state machine
- [x] Add 256-byte memory and a reference program
- [x] Integrate the complete CPU and run instruction-level tests
- [x] Add a vendor-neutral FPGA top level and clock/reset conditioning
- [ ] Add board-specific pin constraints and demonstrate on hardware

## Design rule

Every new block should include a self-checking test before it is integrated into the CPU. The goal is not only to make the processor run, but to make each abstraction—from transistor cell to instruction—easy to inspect and explain.
