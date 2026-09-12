library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity gpio_output_port8_tb is
end entity;

architecture test of gpio_output_port8_tb is
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';
    signal address : std_logic_vector(7 downto 0) := (others => '0');
    signal write_enable : std_logic := '0';
    signal data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal address_match : std_logic;
    signal data_out : std_logic_vector(7 downto 0);
begin
    dut : entity work.gpio_output_port8(structural)
        generic map (
            PORT_ADDRESS => x"FE"
        )
        port map (
            clock => clock,
            reset => reset,
            address => address,
            write_enable => write_enable,
            data_in => data_in,
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
        write_enable <= '1';
        address <= x"FE";
        data_in <= x"FF";
        tick;
        reset <= '0';
        assert data_out = x"00"
            report "reset did not clear the GPIO output register" severity failure;

        -- Every non-matching address must leave the output unchanged, and only
        -- FE may assert the decoder's match output.
        for address_value in 0 to 255 loop
            address <= std_logic_vector(to_unsigned(address_value, 8));
            data_in <= std_logic_vector(to_unsigned(address_value, 8));
            wait for 1 ns;
            if address_value = 16#FE# then
                assert address_match = '1'
                    report "FE did not select the GPIO port" severity failure;
            else
                assert address_match = '0'
                    report "non-GPIO address selected the GPIO port" severity failure;
                tick;
                assert data_out = x"00"
                    report "non-GPIO address changed the output register" severity failure;
            end if;
        end loop;

        address <= x"FE";
        data_in <= x"A5";
        tick;
        assert data_out = x"A5"
            report "selected write did not update the GPIO output" severity failure;

        write_enable <= '0';
        data_in <= x"5A";
        tick;
        assert data_out = x"A5"
            report "disabled write changed the GPIO output" severity failure;

        reset <= '1';
        tick;
        assert data_out = x"00"
            report "reset did not recover the GPIO output" severity failure;

        report "PASS: GPIO output decoder and register" severity note;
        finish;
    end process;
end architecture;
