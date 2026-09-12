library ieee;
use ieee.std_logic_1164.all;

-- Write/readback register selected by one address in the CPU memory map.
entity gpio_output_port8 is
    generic (
        PORT_ADDRESS : std_logic_vector(7 downto 0) := x"FE"
    );
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        address       : in  std_logic_vector(7 downto 0);
        write_enable  : in  std_logic;
        data_in       : in  std_logic_vector(7 downto 0);
        address_match : out std_logic;
        data_out      : out std_logic_vector(7 downto 0)
    );
end entity;

architecture structural of gpio_output_port8 is
    signal selected : std_logic;
    signal register_load : std_logic;
begin
    address_decoder : entity work.byte_equal8(structural)
        generic map (
            expected_value => PORT_ADDRESS
        )
        port map (
            value => address,
            is_equal => selected
        );

    write_gate : entity work.and2(structural)
        port map (
            a => selected,
            b => write_enable,
            y => register_load
        );

    output_register : entity work.register8(rtl)
        port map (
            clk => clock,
            reset => reset,
            load_enable => register_load,
            data_in => data_in,
            data_out => data_out
        );

    address_match <= selected;
end architecture;
