library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.memory_pkg.all;

entity memory256x8_tb is
end entity;

architecture test of memory256x8_tb is
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';
    signal address : std_logic_vector(7 downto 0) := (others => '0');
    signal write_enable : std_logic := '0';
    signal data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out : std_logic_vector(7 downto 0);
begin
    dut : entity work.memory256x8(structural)
        port map (
            clock => clock,
            reset => reset,
            address => address,
            write_enable => write_enable,
            data_in => data_in,
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

        function test_pattern (constant address_value : natural)
            return std_logic_vector is
        begin
            return std_logic_vector(to_unsigned(
                (address_value * 73 + 19) mod 256, 8));
        end function;
    begin
        reset <= '1';
        tick;
        reset <= '0';

        -- Reset must restore every byte of the reference image.
        for address_value in 0 to 255 loop
            address <= std_logic_vector(to_unsigned(address_value, 8));
            wait for 1 ns;
            assert data_out = REFERENCE_PROGRAM(address_value)
                report "reference image mismatch at address " &
                    integer'image(address_value)
                severity failure;
        end loop;

        -- Write and immediately read back a distinct value at every address.
        write_enable <= '1';
        for address_value in 0 to 255 loop
            address <= std_logic_vector(to_unsigned(address_value, 8));
            data_in <= test_pattern(address_value);
            tick;
            assert data_out = test_pattern(address_value)
                report "write/read mismatch at address " &
                    integer'image(address_value)
                severity failure;
        end loop;

        -- Sweep the complete memory again with writes disabled.
        write_enable <= '0';
        for address_value in 0 to 255 loop
            address <= std_logic_vector(to_unsigned(address_value, 8));
            wait for 1 ns;
            assert data_out = test_pattern(address_value)
                report "retention mismatch at address " &
                    integer'image(address_value)
                severity failure;
        end loop;

        -- A disabled write must leave the selected byte unchanged.
        address <= x"2A";
        data_in <= x"AA";
        tick;
        assert data_out = test_pattern(16#2A#)
            report "disabled write changed memory" severity failure;

        -- Reset has priority over a simultaneous write and reloads the image.
        write_enable <= '1';
        reset <= '1';
        tick;
        reset <= '0';
        write_enable <= '0';
        for address_value in 0 to 255 loop
            address <= std_logic_vector(to_unsigned(address_value, 8));
            wait for 1 ns;
            assert data_out = REFERENCE_PROGRAM(address_value)
                report "reset reload mismatch at address " &
                    integer'image(address_value)
                severity failure;
        end loop;

        report "PASS: 256-byte structural memory and reference image" severity note;
        finish;
    end process;
end architecture;
