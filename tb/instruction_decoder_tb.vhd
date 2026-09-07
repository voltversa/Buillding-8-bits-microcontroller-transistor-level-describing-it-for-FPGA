library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.alu_pkg.all;
use work.instruction_pkg.all;

entity instruction_decoder_tb is
end entity;

architecture test of instruction_decoder_tb is
    signal opcode           : opcode_t := (others => '0');
    signal instruction_kind : instruction_kind_t;
    signal alu_operation    : alu_operation_t;
    signal has_operand      : std_logic;
    signal valid            : std_logic;
begin
    dut : entity work.instruction_decoder(structural)
        port map (
            opcode           => opcode,
            instruction_kind => instruction_kind,
            alu_operation    => alu_operation,
            has_operand      => has_operand,
            valid            => valid
        );

    stimulus : process
        variable expected_kind : instruction_kind_t;
        variable expected_alu : alu_operation_t;
        variable expected_operand : std_logic;
        variable expected_valid : std_logic;
        variable valid_opcode_count : natural := 0;
    begin
        for opcode_value in 0 to 255 loop
            opcode <= std_logic_vector(to_unsigned(opcode_value, opcode'length));
            wait for 1 ns;

            expected_kind := INSTRUCTION_INVALID;
            expected_alu := ALU_PASS_A;
            expected_operand := '0';
            expected_valid := '0';

            case opcode_value is
                when 16#00# =>
                    expected_kind := INSTRUCTION_NOP;
                    expected_valid := '1';
                when 16#10# =>
                    expected_kind := INSTRUCTION_LOAD_IMMEDIATE;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#11# =>
                    expected_kind := INSTRUCTION_LOAD_MEMORY;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#12# =>
                    expected_kind := INSTRUCTION_STORE_MEMORY;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#20# =>
                    expected_kind := INSTRUCTION_ALU;
                    expected_alu := ALU_ADD;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#21# =>
                    expected_kind := INSTRUCTION_ALU;
                    expected_alu := ALU_SUB;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#22# =>
                    expected_kind := INSTRUCTION_ALU;
                    expected_alu := ALU_AND;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#23# =>
                    expected_kind := INSTRUCTION_ALU;
                    expected_alu := ALU_OR;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#24# =>
                    expected_kind := INSTRUCTION_ALU;
                    expected_alu := ALU_XOR;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#30# =>
                    expected_kind := INSTRUCTION_JUMP;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#31# =>
                    expected_kind := INSTRUCTION_JUMP_ZERO;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#32# =>
                    expected_kind := INSTRUCTION_JUMP_CARRY;
                    expected_operand := '1';
                    expected_valid := '1';
                when 16#FF# =>
                    expected_kind := INSTRUCTION_HALT;
                    expected_valid := '1';
                when others =>
                    null;
            end case;

            if expected_valid = '1' then
                valid_opcode_count := valid_opcode_count + 1;
            end if;

            assert instruction_kind = expected_kind
                report "instruction kind mismatch for opcode " &
                    integer'image(opcode_value)
                severity failure;
            assert alu_operation = expected_alu
                report "ALU selector mismatch for opcode " &
                    integer'image(opcode_value)
                severity failure;
            assert has_operand = expected_operand
                report "operand-length mismatch for opcode " &
                    integer'image(opcode_value)
                severity failure;
            assert valid = expected_valid
                report "valid flag mismatch for opcode " &
                    integer'image(opcode_value)
                severity failure;
        end loop;

        assert valid_opcode_count = 13
            report "testbench expected exactly 13 defined opcodes"
            severity failure;

        report "PASS: all 256 opcodes decoded; 13 are defined" severity note;
        finish;
    end process;
end architecture;
