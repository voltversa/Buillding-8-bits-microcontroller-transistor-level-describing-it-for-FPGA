# CMOS foundations

The processor is explained from transistor behavior upward, but its FPGA implementation is written in synthesizable VHDL. An FPGA configuration selects pre-fabricated lookup tables, flip-flops, and routing; it does not create individual NMOS and PMOS transistors. Keeping this boundary explicit prevents a simulation model from being mistaken for synthesizable hardware.

## Complementary pull networks

A static CMOS gate has two complementary networks:

- The **PMOS pull-up network** connects the output to `VDD` for input combinations that produce logic `1`.
- The **NMOS pull-down network** connects the output to ground for input combinations that produce logic `0`.

Ideally, exactly one network conducts in every stable input state.

| Cell | Pull-up network | Pull-down network | Minimum transistors |
|---|---|---|---:|
| Inverter | One PMOS | One NMOS | 2 |
| 2-input NAND | Two PMOS in parallel | Two NMOS in series | 4 |
| 2-input NOR | Two PMOS in series | Two NMOS in parallel | 4 |
| 2-input AND | NAND followed by inverter | NAND followed by inverter | 6 |
| 2-input OR | NOR followed by inverter | NOR followed by inverter | 6 |

The VHDL entities in `transistor_model/cmos_cells.vhd` verify the logical behavior of the first three networks. Their synthesizable counterparts are composed structurally in `rtl/logic/gates.vhd`.

## Why NAND and NOR come first

NAND and NOR are universal gates: either one can be used to construct every Boolean function. They also map directly to simple complementary CMOS networks. The first arithmetic block, the 1-bit full adder, is then assembled from reusable Boolean cells instead of using VHDL's `+` operator. This keeps the implementation traceable from equations to hardware.
