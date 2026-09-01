# Transistor-to-FPGA 8-bit Microcontroller

An educational 8-bit microcontroller built from the bottom up. The project connects two views of digital hardware:

1. **CMOS logic models in VHDL** show the Boolean behavior produced by NMOS and PMOS pull-up/pull-down networks.
2. **Synthesizable structural VHDL-2008** composes equivalent gates into datapath blocks that can be implemented on an FPGA.

> FPGA tools cannot map individual NMOS/PMOS devices. The `transistor_model/` tree records the transistor-network behavior in VHDL for learning, while `rtl/` contains the structural VHDL used for synthesis. The physical pull-up/pull-down arrangements are documented in [docs/cmos-foundations.md](docs/cmos-foundations.md).

## Current milestone

Milestone 1 establishes a tested logic foundation:

- CMOS inverter, NAND, and NOR behavior models in VHDL
- synthesizable AND, OR, XOR, and NOT cells
- structural 1-bit full adder
- structural 8-bit ripple-carry adder
- exhaustive adder verification across all 131,072 input combinations
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
| FPGA interface | Clock, reset, GPIO, and a simple debug bus |

The first instruction set and cycle-level behavior are documented in [docs/architecture.md](docs/architecture.md).

## Repository layout

```text
transistor_model/  Educational VHDL models of CMOS-cell behavior
rtl/logic/         Synthesizable structural VHDL logic and arithmetic
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
- [ ] Build the 8-bit ALU and flags
- [ ] Add registers, program counter, and internal bus
- [ ] Implement the instruction decoder and control state machine
- [ ] Add 256-byte memory and a reference program
- [ ] Integrate the complete CPU and run instruction-level tests
- [ ] Add an FPGA top level, constraints, and board demonstration

## Design rule

Every new block should include a self-checking test before it is integrated into the CPU. The goal is not only to make the processor run, but to make each abstraction—from transistor cell to instruction—easy to inspect and explain.
