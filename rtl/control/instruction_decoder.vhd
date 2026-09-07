library ieee;
use ieee.std_logic_1164.all;
use work.alu_pkg.all;
use work.instruction_pkg.all;

-- Structural opcode recognition with deterministic outputs for reserved values.
entity instruction_decoder is
    port (
        opcode           : in  opcode_t;
        instruction_kind : out instruction_kind_t;
        alu_operation    : out alu_operation_t;
        has_operand      : out std_logic;
        valid            : out std_logic
    );
end entity;

architecture structural of instruction_decoder is
    signal match_nop : std_logic;
    signal match_ldi : std_logic;
    signal match_lda : std_logic;
    signal match_sta : std_logic;
    signal match_add : std_logic;
    signal match_sub : std_logic;
    signal match_and : std_logic;
    signal match_or  : std_logic;
    signal match_xor : std_logic;
    signal match_jmp : std_logic;
    signal match_jz  : std_logic;
    signal match_jc  : std_logic;
    signal match_hlt : std_logic;

    signal match_terms : std_logic_vector(15 downto 0);
    signal valid_pairs : std_logic_vector(7 downto 0);
    signal valid_quads : std_logic_vector(3 downto 0);
    signal valid_octets : std_logic_vector(1 downto 0);
    signal one_byte_instruction : std_logic;
    signal operand_instruction : std_logic;
begin
    decode_nop : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_NOP)
        port map (opcode => opcode, is_match => match_nop);
    decode_ldi : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_LDI)
        port map (opcode => opcode, is_match => match_ldi);
    decode_lda : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_LDA)
        port map (opcode => opcode, is_match => match_lda);
    decode_sta : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_STA)
        port map (opcode => opcode, is_match => match_sta);
    decode_add : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_ADD)
        port map (opcode => opcode, is_match => match_add);
    decode_sub : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_SUB)
        port map (opcode => opcode, is_match => match_sub);
    decode_and : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_AND)
        port map (opcode => opcode, is_match => match_and);
    decode_or : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_OR)
        port map (opcode => opcode, is_match => match_or);
    decode_xor : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_XOR)
        port map (opcode => opcode, is_match => match_xor);
    decode_jmp : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_JMP)
        port map (opcode => opcode, is_match => match_jmp);
    decode_jz : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_JZ)
        port map (opcode => opcode, is_match => match_jz);
    decode_jc : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_JC)
        port map (opcode => opcode, is_match => match_jc);
    decode_hlt : entity work.opcode_match8(structural)
        generic map (expected_opcode => OPCODE_HLT)
        port map (opcode => opcode, is_match => match_hlt);

    match_terms(0) <= match_nop;
    match_terms(1) <= match_ldi;
    match_terms(2) <= match_lda;
    match_terms(3) <= match_sta;
    match_terms(4) <= match_add;
    match_terms(5) <= match_sub;
    match_terms(6) <= match_and;
    match_terms(7) <= match_or;
    match_terms(8) <= match_xor;
    match_terms(9) <= match_jmp;
    match_terms(10) <= match_jz;
    match_terms(11) <= match_jc;
    match_terms(12) <= match_hlt;
    match_terms(15 downto 13) <= (others => '0');

    reduce_valid_pairs : for pair_index in 0 to 7 generate
        valid_pair_gate : entity work.or2(structural)
            port map (
                a => match_terms(pair_index * 2),
                b => match_terms(pair_index * 2 + 1),
                y => valid_pairs(pair_index)
            );
    end generate;

    reduce_valid_quads : for quad_index in 0 to 3 generate
        valid_quad_gate : entity work.or2(structural)
            port map (
                a => valid_pairs(quad_index * 2),
                b => valid_pairs(quad_index * 2 + 1),
                y => valid_quads(quad_index)
            );
    end generate;

    reduce_valid_octets : for octet_index in 0 to 1 generate
        valid_octet_gate : entity work.or2(structural)
            port map (
                a => valid_quads(octet_index * 2),
                b => valid_quads(octet_index * 2 + 1),
                y => valid_octets(octet_index)
            );
    end generate;

    valid_gate : entity work.or2(structural)
        port map (a => valid_octets(0), b => valid_octets(1), y => valid);

    one_byte_gate : entity work.or2(structural)
        port map (a => match_nop, b => match_hlt, y => one_byte_instruction);

    operand_inverter : entity work.inv1(rtl)
        port map (a => one_byte_instruction, y => operand_instruction);

    operand_gate : entity work.and2(structural)
        port map (a => valid, b => operand_instruction, y => has_operand);

    with opcode select
        instruction_kind <= INSTRUCTION_NOP            when OPCODE_NOP,
                            INSTRUCTION_LOAD_IMMEDIATE when OPCODE_LDI,
                            INSTRUCTION_LOAD_MEMORY    when OPCODE_LDA,
                            INSTRUCTION_STORE_MEMORY   when OPCODE_STA,
                            INSTRUCTION_ALU            when OPCODE_ADD,
                            INSTRUCTION_ALU            when OPCODE_SUB,
                            INSTRUCTION_ALU            when OPCODE_AND,
                            INSTRUCTION_ALU            when OPCODE_OR,
                            INSTRUCTION_ALU            when OPCODE_XOR,
                            INSTRUCTION_JUMP           when OPCODE_JMP,
                            INSTRUCTION_JUMP_ZERO      when OPCODE_JZ,
                            INSTRUCTION_JUMP_CARRY     when OPCODE_JC,
                            INSTRUCTION_HALT           when OPCODE_HLT,
                            INSTRUCTION_INVALID        when others;

    with opcode select
        alu_operation <= ALU_ADD    when OPCODE_ADD,
                         ALU_SUB    when OPCODE_SUB,
                         ALU_AND    when OPCODE_AND,
                         ALU_OR     when OPCODE_OR,
                         ALU_XOR    when OPCODE_XOR,
                         ALU_PASS_A when others;
end architecture;
