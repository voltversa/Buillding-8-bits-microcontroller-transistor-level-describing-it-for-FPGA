library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity gpio_input_port8_tb is
end entity;

architecture test of gpio_input_port8_tb is
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';
    signal address : std_logic_vector(7 downto 0) := (others => '0');
    signal gpio_in : std_logic_vector(7 downto 0) := (others => '0');
    signal address_match : std_logic;
    signal data_out : std_logic_vector(7 downto 0);
begin
    dut : entity work.gpio_input_port8(structural)
        generic map (
            PORT_ADDRESS => x"FD"
        )
        port map (
            clock => clock,
            reset => reset,
            address => address,
            gpio_in => gpio_in,
            address_match => address_match,
            data_out => data_out
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
    begin
        reset <= '1';
        gpio_in <= x"FF";
        tick;
        reset <= '0';
        assert data_out = x"00"
            report "reset did not clear the synchronized GPIO input" severity failure;

        -- Check the complete address decoder independently of sampled input data.
        for address_value in 0 to 255 loop
            address <= std_logic_vector(to_unsigned(address_value, 8));
            wait for 1 ns;
            if address_value = 16#FD# then
                assert address_match = '1'
                    report "FD did not select the GPIO input port" severity failure;
            else
                assert address_match = '0'
                    report "non-GPIO address selected the GPIO input port" severity failure;
            end if;
        end loop;

        -- A changed asynchronous input becomes visible only after two clocks.
        gpio_in <= x"A5";
        tick;
        assert data_out = x"00"
            report "GPIO input bypassed the second synchronizer stage" severity failure;
        tick;
        assert data_out = x"A5"
            report "GPIO input did not propagate through both stages" severity failure;

        gpio_in <= x"5A";
        tick;
        assert data_out = x"A5"
            report "GPIO input changed after only one synchronization edge" severity failure;
        tick;
        assert data_out = x"5A"
            report "second GPIO input value was not synchronized" severity failure;

        reset <= '1';
        tick;
        assert data_out = x"00"
            report "reset did not recover the GPIO input port" severity failure;

        report "PASS: GPIO input decoder and two-stage synchronizer" severity note;
        finish;
    end process;
end architecture;
