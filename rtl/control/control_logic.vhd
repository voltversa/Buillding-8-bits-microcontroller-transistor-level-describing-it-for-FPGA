library ieee;
use ieee.std_logic_1164.all;
use work.bus_pkg.all;
use work.instruction_pkg.all;
use work.control_pkg.all;

-- Combinational next-state and datapath-control network. Storage is kept in
-- control_unit so this block contains no inferred latches or clocked state.
entity control_logic is
    port (
        state_current        : in  control_state_t;
        instruction_kind     : in  instruction_kind_t;
        instruction_valid    : in  std_logic;
        instruction_operand  : in  std_logic;
        zero_flag            : in  std_logic;
        carry_flag           : in  std_logic;
        state_next           : out control_state_t;
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

architecture rtl of control_logic is
begin
    decode_controls : process (all)
    begin
        state_next <= CONTROL_FAULT;
        bus_select <= BUS_ZERO_0;
        address_from_operand <= '0';
        instruction_load <= '0';
        operand_load <= '0';
        accumulator_load <= '0';
        flags_load <= '0';
        pc_increment <= '0';
        pc_load <= '0';
        memory_write <= '0';
        halted <= '0';
        fault <= '0';

        case state_current is
            when CONTROL_FETCH =>
                -- MEM[PC] is placed on the bus and captured by the instruction
                -- register while PC advances to the next byte.
                state_next <= CONTROL_DECODE;
                bus_select <= BUS_MEMORY;
                instruction_load <= '1';
                pc_increment <= '1';

            when CONTROL_DECODE =>
                if instruction_valid = '1' then
                    if instruction_operand = '1' then
                        state_next <= CONTROL_OPERAND_FETCH;
                    elsif instruction_operand = '0' then
                        state_next <= CONTROL_EXECUTE;
                    else
                        state_next <= CONTROL_FAULT;
                    end if;
                else
                    state_next <= CONTROL_FAULT;
                end if;

            when CONTROL_OPERAND_FETCH =>
                -- The second instruction byte is fetched from MEM[PC].
                state_next <= CONTROL_EXECUTE;
                bus_select <= BUS_MEMORY;
                operand_load <= '1';
                pc_increment <= '1';

            when CONTROL_EXECUTE =>
                case instruction_kind is
                    when INSTRUCTION_NOP =>
                        state_next <= CONTROL_FETCH;

                    when INSTRUCTION_LOAD_IMMEDIATE =>
                        state_next <= CONTROL_FETCH;
                        bus_select <= BUS_OPERAND;
                        accumulator_load <= '1';

                    when INSTRUCTION_LOAD_MEMORY =>
                        state_next <= CONTROL_FETCH;
                        bus_select <= BUS_MEMORY;
                        address_from_operand <= '1';
                        accumulator_load <= '1';

                    when INSTRUCTION_STORE_MEMORY =>
                        state_next <= CONTROL_FETCH;
                        bus_select <= BUS_ACCUMULATOR;
                        address_from_operand <= '1';
                        memory_write <= '1';

                    when INSTRUCTION_ALU =>
                        state_next <= CONTROL_FETCH;
                        bus_select <= BUS_ALU;
                        address_from_operand <= '1';
                        accumulator_load <= '1';
                        flags_load <= '1';

                    when INSTRUCTION_JUMP =>
                        state_next <= CONTROL_FETCH;
                        bus_select <= BUS_OPERAND;
                        pc_load <= '1';

                    when INSTRUCTION_JUMP_ZERO =>
                        state_next <= CONTROL_FETCH;
                        bus_select <= BUS_OPERAND;
                        if zero_flag = '1' then
                            pc_load <= '1';
                        end if;

                    when INSTRUCTION_JUMP_CARRY =>
                        state_next <= CONTROL_FETCH;
                        bus_select <= BUS_OPERAND;
                        if carry_flag = '1' then
                            pc_load <= '1';
                        end if;

                    when INSTRUCTION_HALT =>
                        state_next <= CONTROL_HALTED;

                    when others =>
                        state_next <= CONTROL_FAULT;
                end case;

            when CONTROL_HALTED =>
                state_next <= CONTROL_HALTED;
                halted <= '1';

            when CONTROL_FAULT =>
                state_next <= CONTROL_FAULT;
                fault <= '1';

            when others =>
                -- Both unused binary state encodings enter the safe fault lock.
                state_next <= CONTROL_FAULT;
        end case;
    end process;
end architecture;
