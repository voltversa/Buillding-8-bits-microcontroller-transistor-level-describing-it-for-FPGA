GHDL ?= ghdl
GHDL_FLAGS := --std=08
BUILD_DIR := build/ghdl

.PHONY: test test-cmos test-adder test-alu test-datapath test-bus test-decoder test-control test-memory test-io test-cpu test-fpga clean

test: test-cmos test-adder test-alu test-datapath test-bus test-decoder test-control test-memory test-io test-cpu test-fpga

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

test-cmos: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		transistor_model/cmos_cells.vhd tb/cmos_cells_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) cmos_cells_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) cmos_cells_tb \
		--assert-level=error

test-adder: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/gates.vhd \
		rtl/logic/full_adder_1bit.vhd \
		rtl/logic/ripple_carry_adder_8bit.vhd \
		tb/ripple_carry_adder_8bit_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		ripple_carry_adder_8bit_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		ripple_carry_adder_8bit_tb --assert-level=error

test-alu: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/alu_pkg.vhd \
		rtl/logic/gates.vhd \
		rtl/logic/full_adder_1bit.vhd \
		rtl/logic/ripple_carry_adder_8bit.vhd \
		rtl/logic/alu8.vhd \
		tb/alu8_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) alu8_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) alu8_tb \
		--assert-level=error

test-datapath: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/gates.vhd \
		rtl/logic/full_adder_1bit.vhd \
		rtl/logic/ripple_carry_adder_8bit.vhd \
		rtl/datapath/register8.vhd \
		rtl/datapath/program_counter8.vhd \
		tb/datapath_registers_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		datapath_registers_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		datapath_registers_tb --assert-level=error

test-bus: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/gates.vhd \
		rtl/logic/mux2_1bit.vhd \
		rtl/datapath/bus_pkg.vhd \
		rtl/datapath/internal_bus8.vhd \
		tb/internal_bus8_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) internal_bus8_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) internal_bus8_tb \
		--assert-level=error

test-decoder: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/alu_pkg.vhd \
		rtl/logic/gates.vhd \
		rtl/control/instruction_pkg.vhd \
		rtl/control/opcode_match8.vhd \
		rtl/control/instruction_decoder.vhd \
		tb/instruction_decoder_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) instruction_decoder_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) instruction_decoder_tb \
		--assert-level=error

test-control: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/datapath/bus_pkg.vhd \
		rtl/datapath/register8.vhd \
		rtl/control/instruction_pkg.vhd \
		rtl/control/control_pkg.vhd \
		rtl/control/control_logic.vhd \
		rtl/control/control_unit.vhd \
		tb/control_unit_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) control_unit_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) control_unit_tb \
		--assert-level=error

test-memory: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/gates.vhd \
		rtl/logic/mux2_1bit.vhd \
		rtl/logic/byte_equal8.vhd \
		rtl/control/instruction_pkg.vhd \
		rtl/memory/memory_pkg.vhd \
		rtl/memory/memory_byte.vhd \
		rtl/memory/memory256x8.vhd \
		tb/memory256x8_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) memory256x8_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) memory256x8_tb \
		--assert-level=error

test-io: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/gates.vhd \
		rtl/logic/byte_equal8.vhd \
		rtl/datapath/register8.vhd \
		rtl/io/gpio_output_port8.vhd \
		rtl/io/gpio_input_port8.vhd \
		tb/gpio_output_port8_tb.vhd \
		tb/gpio_input_port8_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) gpio_output_port8_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) gpio_output_port8_tb \
		--assert-level=error
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) gpio_input_port8_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) gpio_input_port8_tb \
		--assert-level=error

test-cpu: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/alu_pkg.vhd \
		rtl/logic/gates.vhd \
		rtl/logic/mux2_1bit.vhd \
		rtl/logic/full_adder_1bit.vhd \
		rtl/logic/ripple_carry_adder_8bit.vhd \
		rtl/logic/alu8.vhd \
		rtl/logic/byte_equal8.vhd \
		rtl/datapath/bus_pkg.vhd \
		rtl/datapath/register8.vhd \
		rtl/datapath/program_counter8.vhd \
		rtl/datapath/internal_bus8.vhd \
		rtl/control/instruction_pkg.vhd \
		rtl/control/opcode_match8.vhd \
		rtl/control/instruction_decoder.vhd \
		rtl/control/control_pkg.vhd \
		rtl/control/control_logic.vhd \
		rtl/control/control_unit.vhd \
		rtl/memory/memory_pkg.vhd \
		rtl/memory/memory_byte.vhd \
		rtl/memory/memory256x8.vhd \
		rtl/io/gpio_output_port8.vhd \
		rtl/io/gpio_input_port8.vhd \
		rtl/cpu/cpu8.vhd \
		tb/cpu8_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) cpu8_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) cpu8_tb \
		--assert-level=error

test-fpga: $(BUILD_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(BUILD_DIR) \
		rtl/logic/alu_pkg.vhd \
		rtl/logic/gates.vhd \
		rtl/logic/mux2_1bit.vhd \
		rtl/logic/full_adder_1bit.vhd \
		rtl/logic/ripple_carry_adder_8bit.vhd \
		rtl/logic/alu8.vhd \
		rtl/logic/byte_equal8.vhd \
		rtl/datapath/bus_pkg.vhd \
		rtl/datapath/register8.vhd \
		rtl/datapath/program_counter8.vhd \
		rtl/datapath/internal_bus8.vhd \
		rtl/control/instruction_pkg.vhd \
		rtl/control/opcode_match8.vhd \
		rtl/control/instruction_decoder.vhd \
		rtl/control/control_pkg.vhd \
		rtl/control/control_logic.vhd \
		rtl/control/control_unit.vhd \
		rtl/memory/memory_pkg.vhd \
		rtl/memory/memory_byte.vhd \
		rtl/memory/memory256x8.vhd \
		rtl/io/gpio_output_port8.vhd \
		rtl/io/gpio_input_port8.vhd \
		rtl/cpu/cpu8.vhd \
		rtl/fpga/reset_synchronizer.vhd \
		rtl/fpga/clock_enable_generator.vhd \
		rtl/fpga/fpga_demo_top.vhd \
		tb/fpga_demo_top_tb.vhd
	$(GHDL) -e $(GHDL_FLAGS) --workdir=$(BUILD_DIR) fpga_demo_top_tb
	$(GHDL) -r $(GHDL_FLAGS) --workdir=$(BUILD_DIR) fpga_demo_top_tb \
		--assert-level=error

clean:
	rm -rf $(BUILD_DIR)
