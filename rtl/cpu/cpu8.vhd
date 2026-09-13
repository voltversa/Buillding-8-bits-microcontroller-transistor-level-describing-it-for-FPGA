library ieee;
use ieee.std_logic_1164.all;
use work.alu_pkg.all;
use work.bus_pkg.all;
use work.instruction_pkg.all;
use work.control_pkg.all;
use work.memory_pkg.all;

-- Complete structural eight-bit accumulator CPU. The clock-enable input lets an
-- FPGA wrapper single-step the processor without creating a second clock domain.
entity cpu8 is
    generic (
        initial_content : memory_image_t := REFERENCE_PROGRAM
    );
    port (
        clock                : in  std_logic;
        reset                : in  std_logic;
        clock_enable         : in  std_logic;
        gpio_input           : in  std_logic_vector(7 downto 0);
        memory_debug_enable  : in  std_logic;
        memory_debug_address : in  std_logic_vector(7 downto 0);
        memory_debug_data    : out std_logic_vector(7 downto 0);
        accumulator_debug    : out std_logic_vector(7 downto 0);
        operand_debug        : out std_logic_vector(7 downto 0);
        instruction_debug    : out std_logic_vector(7 downto 0);
        pc_debug             : out std_logic_vector(7 downto 0);
        zero_flag_debug      : out std_logic;
        carry_flag_debug     : out std_logic;
        gpio_output          : out std_logic_vector(7 downto 0);
        state_debug          : out control_state_t;
        halted               : out std_logic;
        fault                : out std_logic
    );
end entity;

architecture structural of cpu8 is
    signal accumulator_value : std_logic_vector(7 downto 0);
    signal operand_value : std_logic_vector(7 downto 0);
    signal instruction_value : std_logic_vector(7 downto 0);
    signal pc_value : std_logic_vector(7 downto 0);
    signal flags_input : std_logic_vector(7 downto 0);
    signal flags_value : std_logic_vector(7 downto 0);

    signal decoded_kind : instruction_kind_t;
    signal decoded_alu_operation : alu_operation_t;
    signal decoded_has_operand : std_logic;
    signal decoded_valid : std_logic;

    signal selected_bus : std_logic_vector(7 downto 0);
    signal selected_bus_source : bus_select_t;
    signal alu_result : std_logic_vector(7 downto 0);
    signal alu_carry : std_logic;
    signal alu_zero : std_logic;

    signal address_from_operand : std_logic;
    signal processor_memory_address : std_logic_vector(7 downto 0);
    signal selected_memory_address : std_logic_vector(7 downto 0);
    signal memory_data : std_logic_vector(7 downto 0);
    signal ram_data : std_logic_vector(7 downto 0);
    signal gpio_value : std_logic_vector(7 downto 0);
    signal gpio_input_value : std_logic_vector(7 downto 0);
    signal gpio_address_selected : std_logic;
    signal gpio_input_address_selected : std_logic;
    signal any_gpio_address_selected : std_logic;
    signal gpio_address_not_selected : std_logic;
    signal ram_or_input_data : std_logic_vector(7 downto 0);
    signal memory_write_control : std_logic;
    signal memory_write_enable : std_logic;
    signal safe_write_enable : std_logic;
    signal memory_debug_disabled : std_logic;

    signal instruction_load_control : std_logic;
    signal operand_load_control : std_logic;
    signal accumulator_load_control : std_logic;
    signal flags_load_control : std_logic;
    signal pc_increment_control : std_logic;
    signal pc_load_control : std_logic;
    signal instruction_load_enabled : std_logic;
    signal operand_load_enabled : std_logic;
    signal accumulator_load_enabled : std_logic;
    signal flags_load_enabled : std_logic;
    signal pc_increment_enabled : std_logic;
    signal pc_load_enabled : std_logic;
    signal memory_write_enabled : std_logic;
begin
    accumulator_debug <= accumulator_value;
    operand_debug <= operand_value;
    instruction_debug <= instruction_value;
    pc_debug <= pc_value;
    carry_flag_debug <= flags_value(0);
    zero_flag_debug <= flags_value(1);
    memory_debug_data <= memory_data;
    gpio_output <= gpio_value;

    instruction_register : entity work.register8(rtl)
        port map (
            clk => clock,
            reset => reset,
            load_enable => instruction_load_enabled,
            data_in => selected_bus,
            data_out => instruction_value
        );

    operand_register : entity work.register8(rtl)
        port map (
            clk => clock,
            reset => reset,
            load_enable => operand_load_enabled,
            data_in => selected_bus,
            data_out => operand_value
        );

    accumulator_register : entity work.register8(rtl)
        port map (
            clk => clock,
            reset => reset,
            load_enable => accumulator_load_enabled,
            data_in => selected_bus,
            data_out => accumulator_value
        );

    flags_input <= "000000" & alu_zero & alu_carry;

    flags_register : entity work.register8(rtl)
        port map (
            clk => clock,
            reset => reset,
            load_enable => flags_load_enabled,
            data_in => flags_input,
            data_out => flags_value
        );

    program_counter : entity work.program_counter8(structural)
        port map (
            clk => clock,
            reset => reset,
            load => pc_load_enabled,
            increment => pc_increment_enabled,
            data_in => selected_bus,
            count => pc_value
        );

    decoder : entity work.instruction_decoder(structural)
        port map (
            opcode => instruction_value,
            instruction_kind => decoded_kind,
            alu_operation => decoded_alu_operation,
            has_operand => decoded_has_operand,
            valid => decoded_valid
        );

    controller : entity work.control_unit(structural)
        port map (
            clock => clock,
            reset => reset,
            enable => clock_enable,
            instruction_kind => decoded_kind,
            instruction_valid => decoded_valid,
            instruction_operand => decoded_has_operand,
            zero_flag => flags_value(1),
            carry_flag => flags_value(0),
            state_debug => state_debug,
            bus_select => selected_bus_source,
            address_from_operand => address_from_operand,
            instruction_load => instruction_load_control,
            operand_load => operand_load_control,
            accumulator_load => accumulator_load_control,
            flags_load => flags_load_control,
            pc_increment => pc_increment_control,
            pc_load => pc_load_control,
            memory_write => memory_write_control,
            halted => halted,
            fault => fault
        );

    arithmetic_logic_unit : entity work.alu8(structural)
        port map (
            a => accumulator_value,
            b => memory_data,
            operation => decoded_alu_operation,
            result => alu_result,
            carry_out => alu_carry,
            zero => alu_zero
        );

    data_bus : entity work.internal_bus8(structural)
        port map (
            source_accumulator => accumulator_value,
            source_operand => operand_value,
            source_instruction => instruction_value,
            source_pc => pc_value,
            source_memory => memory_data,
            source_alu => alu_result,
            source_select => selected_bus_source,
            bus_data => selected_bus
        );

    generate_memory_address_bits : for bit_index in 0 to 7 generate
        processor_address_mux : entity work.mux2_1bit(structural)
            port map (
                input_0 => pc_value(bit_index),
                input_1 => operand_value(bit_index),
                select_1 => address_from_operand,
                output_y => processor_memory_address(bit_index)
            );

        debug_address_mux : entity work.mux2_1bit(structural)
            port map (
                input_0 => processor_memory_address(bit_index),
                input_1 => memory_debug_address(bit_index),
                select_1 => memory_debug_enable,
                output_y => selected_memory_address(bit_index)
            );
    end generate;

    debug_enable_inverter : entity work.inv1(rtl)
        port map (
            a => memory_debug_enable,
            y => memory_debug_disabled
        );

    instruction_enable_gate : entity work.and2(structural)
        port map (
            a => instruction_load_control,
            b => clock_enable,
            y => instruction_load_enabled
        );

    operand_enable_gate : entity work.and2(structural)
        port map (
            a => operand_load_control,
            b => clock_enable,
            y => operand_load_enabled
        );

    accumulator_enable_gate : entity work.and2(structural)
        port map (
            a => accumulator_load_control,
            b => clock_enable,
            y => accumulator_load_enabled
        );

    flags_enable_gate : entity work.and2(structural)
        port map (
            a => flags_load_control,
            b => clock_enable,
            y => flags_load_enabled
        );

    pc_increment_enable_gate : entity work.and2(structural)
        port map (
            a => pc_increment_control,
            b => clock_enable,
            y => pc_increment_enabled
        );

    pc_load_enable_gate : entity work.and2(structural)
        port map (
            a => pc_load_control,
            b => clock_enable,
            y => pc_load_enabled
        );

    memory_clock_enable_gate : entity work.and2(structural)
        port map (
            a => memory_write_control,
            b => clock_enable,
            y => memory_write_enabled
        );

    debug_write_interlock : entity work.and2(structural)
        port map (
            a => memory_write_enabled,
            b => memory_debug_disabled,
            y => safe_write_enable
        );

    gpio_port : entity work.gpio_output_port8(structural)
        generic map (
            PORT_ADDRESS => x"FE"
        )
        port map (
            clock => clock,
            reset => reset,
            address => selected_memory_address,
            write_enable => safe_write_enable,
            data_in => selected_bus,
            address_match => gpio_address_selected,
            data_out => gpio_value
        );

    gpio_input_port : entity work.gpio_input_port8(structural)
        generic map (
            PORT_ADDRESS => x"FD"
        )
        port map (
            clock => clock,
            reset => reset,
            address => selected_memory_address,
            gpio_in => gpio_input,
            address_match => gpio_input_address_selected,
            data_out => gpio_input_value
        );

    gpio_select_combiner : entity work.or2(structural)
        port map (
            a => gpio_address_selected,
            b => gpio_input_address_selected,
            y => any_gpio_address_selected
        );

    gpio_select_inverter : entity work.inv1(rtl)
        port map (
            a => any_gpio_address_selected,
            y => gpio_address_not_selected
        );

    ram_write_gate : entity work.and2(structural)
        port map (
            a => safe_write_enable,
            b => gpio_address_not_selected,
            y => memory_write_enable
        );

    unified_memory : entity work.memory256x8(structural)
        generic map (
            initial_content => initial_content
        )
        port map (
            clock => clock,
            reset => reset,
            address => selected_memory_address,
            write_enable => memory_write_enable,
            data_in => selected_bus,
            data_out => ram_data
        );

    generate_io_readback_muxes : for bit_index in 0 to 7 generate
        input_readback_mux : entity work.mux2_1bit(structural)
            port map (
                input_0 => ram_data(bit_index),
                input_1 => gpio_input_value(bit_index),
                select_1 => gpio_input_address_selected,
                output_y => ram_or_input_data(bit_index)
            );

        output_readback_mux : entity work.mux2_1bit(structural)
            port map (
                input_0 => ram_or_input_data(bit_index),
                input_1 => gpio_value(bit_index),
                select_1 => gpio_address_selected,
                output_y => memory_data(bit_index)
            );
    end generate;
end architecture;
