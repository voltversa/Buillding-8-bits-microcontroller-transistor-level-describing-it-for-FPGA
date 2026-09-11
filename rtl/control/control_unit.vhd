library ieee;
use ieee.std_logic_1164.all;
use work.bus_pkg.all;
use work.instruction_pkg.all;
use work.control_pkg.all;

entity control_unit is
    port (
        clock                : in  std_logic;
        reset                : in  std_logic;
        enable               : in  std_logic;
        instruction_kind     : in  instruction_kind_t;
        instruction_valid    : in  std_logic;
        instruction_operand  : in  std_logic;
        zero_flag            : in  std_logic;
        carry_flag           : in  std_logic;
        state_debug          : out control_state_t;
        bus_select           : out bus_select_t;
        address_from_operand : out std_logic;
        instruction_load     : out std_logic;
        operand_load         : out std_logic;
        accumulator_load     : out std_logic;
        flags_load           : out std_logic;
        pc_increment         : out std_logic;
        pc_load              : out std_logic;
        memory_write         : out std_logic;
        halted               : out std_logic;
        fault                : out std_logic
    );
end entity;

architecture structural of control_unit is
    signal state_current : control_state_t;
    signal state_next : control_state_t;
    signal state_register_input : std_logic_vector(7 downto 0);
    signal state_register_output : std_logic_vector(7 downto 0);
begin
    state_register_input <= "00000" & state_next;
    state_current <= state_register_output(2 downto 0);
    state_debug <= state_current;

    state_storage : entity work.register8(rtl)
        port map (
            clk         => clock,
            reset       => reset,
            load_enable => enable,
            data_in     => state_register_input,
            data_out    => state_register_output
        );

    control_network : entity work.control_logic(rtl)
        port map (
            state_current        => state_current,
            instruction_kind     => instruction_kind,
            instruction_valid    => instruction_valid,
            instruction_operand  => instruction_operand,
            zero_flag            => zero_flag,
            carry_flag           => carry_flag,
            state_next           => state_next,
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
end architecture;
