library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.control_pkg.all;
use work.memory_pkg.all;

entity cpu8_tb is
end entity;

architecture test of cpu8_tb is
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';
    signal clock_enable : std_logic := '1';
    signal memory_debug_enable : std_logic := '0';
    signal memory_debug_address : std_logic_vector(7 downto 0) := (others => '0');
    signal memory_debug_data : std_logic_vector(7 downto 0);
    signal accumulator_debug : std_logic_vector(7 downto 0);
    signal operand_debug : std_logic_vector(7 downto 0);
    signal instruction_debug : std_logic_vector(7 downto 0);
    signal pc_debug : std_logic_vector(7 downto 0);
    signal zero_flag_debug : std_logic;
    signal carry_flag_debug : std_logic;
    signal state_debug : control_state_t;
    signal halted : std_logic;
    signal fault : std_logic;
begin
    dut : entity work.cpu8(structural)
        port map (
            clock => clock,
            reset => reset,
            clock_enable => clock_enable,
            memory_debug_enable => memory_debug_enable,
            memory_debug_address => memory_debug_address,
            memory_debug_data => memory_debug_data,
            accumulator_debug => accumulator_debug,
            operand_debug => operand_debug,
            instruction_debug => instruction_debug,
            pc_debug => pc_debug,
            zero_flag_debug => zero_flag_debug,
            carry_flag_debug => carry_flag_debug,
            state_debug => state_debug,
            halted => halted,
            fault => fault
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

        variable executed_cycles : natural := 0;
    begin
        reset <= '1';
        tick;
        reset <= '0';

        assert state_debug = CONTROL_FETCH
            report "CPU did not reset to FETCH" severity failure;
        assert accumulator_debug = x"00" and pc_debug = x"00"
            report "CPU registers did not reset" severity failure;
        assert halted = '0' and fault = '0'
            report "CPU asserted terminal status after reset" severity failure;

        -- Disabling the CPU must hold both controller and datapath state even
        -- though the external system clock continues to toggle.
        clock_enable <= '0';
        for hold_cycle in 1 to 3 loop
            tick;
        end loop;
        assert state_debug = CONTROL_FETCH and pc_debug = x"00" and
            accumulator_debug = x"00"
            report "clock enable did not hold the complete CPU state" severity failure;
        clock_enable <= '1';

        while halted /= '1' and fault /= '1' and executed_cycles < 64 loop
            tick;
            executed_cycles := executed_cycles + 1;
        end loop;

        assert fault = '0'
            report "reference program entered the fault state" severity failure;
        assert halted = '1' and state_debug = CONTROL_HALTED
            report "reference program did not halt" severity failure;
        assert executed_cycles = 23
            report "reference program cycle count mismatch: " &
                integer'image(executed_cycles)
            severity failure;
        assert accumulator_debug = x"0A"
            report "reference program accumulator result mismatch" severity failure;
        assert pc_debug = x"0B"
            report "program counter mismatch after HLT fetch" severity failure;
        assert instruction_debug = x"FF"
            report "instruction register does not contain HLT" severity failure;
        assert operand_debug = x"F1"
            report "operand register mismatch after final STA" severity failure;
        assert zero_flag_debug = '0' and carry_flag_debug = '0'
            report "ADD flags mismatch for 05 + 05" severity failure;

        memory_debug_enable <= '1';
        memory_debug_address <= x"F0";
        wait for 1 ns;
        assert memory_debug_data = x"05"
            report "reference program did not store 05 at F0" severity failure;

        memory_debug_address <= x"F1";
        wait for 1 ns;
        assert memory_debug_data = x"0A"
            report "reference program did not store 0A at F1" severity failure;

        -- The instruction bytes must remain unchanged by data writes.
        for address_value in 0 to 10 loop
            memory_debug_address <= std_logic_vector(to_unsigned(address_value, 8));
            wait for 1 ns;
            assert memory_debug_data = REFERENCE_PROGRAM(address_value)
                report "program byte changed at address " &
                    integer'image(address_value)
                severity failure;
        end loop;

        -- Reset recovers from HALT, clears architectural state, and reloads RAM.
        memory_debug_enable <= '0';
        reset <= '1';
        tick;
        reset <= '0';
        assert state_debug = CONTROL_FETCH and halted = '0' and fault = '0'
            report "CPU did not recover from HALT on reset" severity failure;
        assert accumulator_debug = x"00" and pc_debug = x"00"
            report "CPU state was not cleared by reset" severity failure;

        memory_debug_enable <= '1';
        memory_debug_address <= x"F0";
        wait for 1 ns;
        assert memory_debug_data = x"00"
            report "reset did not restore F0" severity failure;
        memory_debug_address <= x"F1";
        wait for 1 ns;
        assert memory_debug_data = x"00"
            report "reset did not restore F1" severity failure;

        report "PASS: reference program halted after 23 cycles with result 0A" severity note;
        finish;
    end process;
end architecture;
