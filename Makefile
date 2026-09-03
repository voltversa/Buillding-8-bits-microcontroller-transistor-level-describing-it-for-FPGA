GHDL ?= ghdl
GHDL_FLAGS := --std=08
BUILD_DIR := build/ghdl

.PHONY: test test-cmos test-adder test-alu test-datapath clean

test: test-cmos test-adder test-alu test-datapath

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

clean:
	rm -rf $(BUILD_DIR)
