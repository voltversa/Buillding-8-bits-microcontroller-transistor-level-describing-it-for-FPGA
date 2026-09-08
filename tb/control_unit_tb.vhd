library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.bus_pkg.all;
use work.instruction_pkg.all;
use work.control_pkg.all;

entity control_unit_tb is
end entity;

architecture test of control_unit_tb is
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';
    signal instruction_kind : instruction_kind_t := INSTRUCTION_NOP;
    signal instruction_valid : std_logic := '1';
    signal instruction_operand : std_logic := '0';
    signal zero_flag : std_logic := '0';
    signal carry_flag : std_logic := '0';
    signal state_debug : control_state_t;
    signal bus_select : bus_select_t;
    signal address_from_operand : std_logic;
    signal instruction_load : std_logic;
    signal operand_load : std_logic;
    signal accumulator_load : std_logic;
    signal flags_load : std_logic;
    signal pc_increment : std_logic;
    signal pc_load : std_logic;
    signal memory_write : std_logic;
    signal halted : std_logic;
    signal fault : std_logic;
begin
    dut : entity work.control_unit(structural)
        port map (
            clock                => clock,
            reset                => reset,
            instruction_kind     => instruction_kind,
            instruction_valid    => instruction_valid,
            instruction_operand  => instruction_operand,
            zero_flag            => zero_flag,
            carry_flag           => carry_flag,
            state_debug          => state_debug,
            bus_select           => bus_select,
            address_from_operand => address_from_operand,
            instruction_load     => instruction_load,
            operand_load         => operand_load,
            accumulator_load     => accumulator_load,
            flags_load           => flags_load,
            pc_increment         => pc_increment,
            pc_load              => pc_load,
            memory_write         => memory_write,
            halted               => halted,
            fault                => fault
        );

    stimulus : process
        procedure tick is
        begin
            clock <= '0';
            wait for 4 ns;
            clock <= '1';
            wait for 1 ns;
            clock <= '0';
            wait for 5 ns;
        end procedure;

        procedure expect_controls (
            constant step_name : in string;
            constant expected_state : in control_state_t;
            constant expected_bus : in bus_select_t;
            constant expected_address_operand : in std_logic;
            constant expected_instruction_load : in std_logic;
            constant expected_operand_load : in std_logic;
            constant expected_accumulator_load : in std_logic;
            constant expected_flags_load : in std_logic;
            constant expected_pc_increment : in std_logic;
            constant expected_pc_load : in std_logic;
            constant expected_memory_write : in std_logic;
            constant expected_halted : in std_logic;
            constant expected_fault : in std_logic
        ) is
        begin
            assert state_debug = expected_state
                report step_name & ": state mismatch" severity failure;
            assert bus_select = expected_bus
                report step_name & ": bus selector mismatch" severity failure;
            assert address_from_operand = expected_address_operand
                report step_name & ": address selector mismatch" severity failure;
            assert instruction_load = expected_instruction_load
                report step_name & ": instruction-load mismatch" severity failure;
            assert operand_load = expected_operand_load
                report step_name & ": operand-load mismatch" severity failure;
            assert accumulator_load = expected_accumulator_load
                report step_name & ": accumulator-load mismatch" severity failure;
            assert flags_load = expected_flags_load
                report step_name & ": flags-load mismatch" severity failure;
            assert pc_increment = expected_pc_increment
                report step_name & ": PC-increment mismatch" severity failure;
            assert pc_load = expected_pc_load
                report step_name & ": PC-load mismatch" severity failure;
            assert memory_write = expected_memory_write
                report step_name & ": memory-write mismatch" severity failure;
            assert halted = expected_halted
                report step_name & ": halted mismatch" severity failure;
            assert fault = expected_fault
                report step_name & ": fault mismatch" severity failure;
        end procedure;
    begin
        -- Reset establishes FETCH, whose strobes request MEM[PC] -> IR and PC+1.
        reset <= '1';
        tick;
        reset <= '0';
        expect_controls("reset/fetch", CONTROL_FETCH, BUS_MEMORY,
            '0', '1', '0', '0', '0', '1', '0', '0', '0', '0');

        -- One-byte NOP: FETCH -> DECODE -> EXECUTE -> FETCH.
        instruction_kind <= INSTRUCTION_NOP;
        instruction_valid <= '1';
        instruction_operand <= '0';
        tick;
        expect_controls("NOP decode", CONTROL_DECODE, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');
        tick;
        expect_controls("NOP execute", CONTROL_EXECUTE, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');
        tick;
        expect_controls("NOP return", CONTROL_FETCH, BUS_MEMORY,
            '0', '1', '0', '0', '0', '1', '0', '0', '0', '0');

        -- Immediate load exercises the common two-byte operand-fetch cycle.
        instruction_kind <= INSTRUCTION_LOAD_IMMEDIATE;
        instruction_operand <= '1';
        tick;
        expect_controls("LDI decode", CONTROL_DECODE, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');
        tick;
        expect_controls("LDI operand fetch", CONTROL_OPERAND_FETCH, BUS_MEMORY,
            '0', '0', '1', '0', '0', '1', '0', '0', '0', '0');
        tick;
        expect_controls("LDI execute", CONTROL_EXECUTE, BUS_OPERAND,
            '0', '0', '0', '1', '0', '0', '0', '0', '0', '0');
        tick;

        -- Memory load selects the operand byte as the data-memory address.
        instruction_kind <= INSTRUCTION_LOAD_MEMORY;
        tick;
        tick;
        tick;
        expect_controls("LDA execute", CONTROL_EXECUTE, BUS_MEMORY,
            '1', '0', '0', '1', '0', '0', '0', '0', '0', '0');
        tick;

        -- Store uses A as write data and the operand register as the address.
        instruction_kind <= INSTRUCTION_STORE_MEMORY;
        tick;
        tick;
        tick;
        expect_controls("STA execute", CONTROL_EXECUTE, BUS_ACCUMULATOR,
            '1', '0', '0', '0', '0', '0', '0', '1', '0', '0');
        tick;

        -- ALU instructions read MEM[operand], write A, and update both flags.
        instruction_kind <= INSTRUCTION_ALU;
        tick;
        tick;
        tick;
        expect_controls("ALU execute", CONTROL_EXECUTE, BUS_ALU,
            '1', '0', '0', '1', '1', '0', '0', '0', '0', '0');
        tick;

        -- Unconditional and conditional jumps load PC from the operand bus.
        instruction_kind <= INSTRUCTION_JUMP;
        tick;
        tick;
        tick;
        expect_controls("JMP execute", CONTROL_EXECUTE, BUS_OPERAND,
            '0', '0', '0', '0', '0', '0', '1', '0', '0', '0');
        tick;

        instruction_kind <= INSTRUCTION_JUMP_ZERO;
        zero_flag <= '0';
        tick;
        tick;
        tick;
        expect_controls("JZ not taken", CONTROL_EXECUTE, BUS_OPERAND,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');
        zero_flag <= '1';
        wait for 1 ns;
        expect_controls("JZ taken", CONTROL_EXECUTE, BUS_OPERAND,
            '0', '0', '0', '0', '0', '0', '1', '0', '0', '0');
        tick;

        instruction_kind <= INSTRUCTION_JUMP_CARRY;
        carry_flag <= '0';
        tick;
        tick;
        tick;
        expect_controls("JC not taken", CONTROL_EXECUTE, BUS_OPERAND,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');
        carry_flag <= '1';
        wait for 1 ns;
        expect_controls("JC taken", CONTROL_EXECUTE, BUS_OPERAND,
            '0', '0', '0', '0', '0', '0', '1', '0', '0', '0');
        tick;

        -- HLT locks the controller until reset and emits no write strobes.
        instruction_kind <= INSTRUCTION_HALT;
        instruction_operand <= '0';
        tick;
        tick;
        expect_controls("HLT execute", CONTROL_EXECUTE, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');
        tick;
        expect_controls("HLT lock", CONTROL_HALTED, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '1', '0');
        tick;
        expect_controls("HLT remains locked", CONTROL_HALTED, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '1', '0');

        reset <= '1';
        tick;
        reset <= '0';
        expect_controls("reset from halt", CONTROL_FETCH, BUS_MEMORY,
            '0', '1', '0', '0', '0', '1', '0', '0', '0', '0');

        -- An invalid opcode enters a non-writing fault lock until reset.
        instruction_kind <= INSTRUCTION_INVALID;
        instruction_valid <= '0';
        instruction_operand <= '0';
        tick;
        expect_controls("invalid decode", CONTROL_DECODE, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0');
        tick;
        expect_controls("invalid fault", CONTROL_FAULT, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '1');
        tick;
        expect_controls("fault remains locked", CONTROL_FAULT, BUS_ZERO_0,
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '1');

        reset <= '1';
        tick;
        expect_controls("reset from fault", CONTROL_FETCH, BUS_MEMORY,
            '0', '1', '0', '0', '0', '1', '0', '0', '0', '0');

        report "PASS: controller sequencing and all instruction classes" severity note;
        finish;
    end process;
end architecture;
