library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity datapath_registers_tb is
end entity;

architecture test of datapath_registers_tb is
    constant CLOCK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';

    signal register_reset       : std_logic := '1';
    signal register_load_enable : std_logic := '0';
    signal register_data_in     : std_logic_vector(7 downto 0) := (others => '0');
    signal register_data_out    : std_logic_vector(7 downto 0);

    signal counter_reset     : std_logic := '1';
    signal counter_load      : std_logic := '0';
    signal counter_increment : std_logic := '0';
    signal counter_data_in   : std_logic_vector(7 downto 0) := (others => '0');
    signal counter_value     : std_logic_vector(7 downto 0);
begin
    clk <= not clk after CLOCK_PERIOD / 2;

    register_dut : entity work.register8(rtl)
        port map (
            clk         => clk,
            reset       => register_reset,
            load_enable => register_load_enable,
            data_in     => register_data_in,
            data_out    => register_data_out
        );

    counter_dut : entity work.program_counter8(structural)
        port map (
            clk       => clk,
            reset     => counter_reset,
            load      => counter_load,
            increment => counter_increment,
            data_in   => counter_data_in,
            count     => counter_value
        );

    stimulus : process
    begin
        -- Reset both storage blocks.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert register_data_out = x"00"
            report "register did not reset" severity failure;
        assert counter_value = x"00"
            report "program counter did not reset" severity failure;

        register_reset <= '0';
        counter_reset <= '0';

        -- Register load and hold.
        register_data_in <= x"5A";
        register_load_enable <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert register_data_out = x"5A"
            report "register load failed" severity failure;

        register_data_in <= x"A5";
        register_load_enable <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert register_data_out = x"5A"
            report "register hold failed" severity failure;

        -- Counter load has priority over increment.
        counter_data_in <= x"FE";
        counter_load <= '1';
        counter_increment <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert counter_value = x"FE"
            report "program counter load priority failed" severity failure;

        counter_load <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert counter_value = x"FF"
            report "program counter increment failed" severity failure;

        -- Eight-bit wraparound is intentional.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert counter_value = x"00"
            report "program counter wraparound failed" severity failure;

        counter_increment <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert counter_value = x"00"
            report "program counter hold failed" severity failure;

        -- Reset overrides simultaneous loads and increments.
        register_data_in <= x"FF";
        register_load_enable <= '1';
        register_reset <= '1';
        counter_data_in <= x"77";
        counter_load <= '1';
        counter_increment <= '1';
        counter_reset <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert register_data_out = x"00"
            report "register reset priority failed" severity failure;
        assert counter_value = x"00"
            report "program counter reset priority failed" severity failure;

        report "PASS: register and program-counter sequencing" severity note;
        finish;
    end process;
end architecture;
