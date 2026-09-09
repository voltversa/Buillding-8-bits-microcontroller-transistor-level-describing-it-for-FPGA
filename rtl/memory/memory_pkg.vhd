library ieee;
use ieee.std_logic_1164.all;
use work.instruction_pkg.all;

package memory_pkg is
    type memory_image_t is array (0 to 255) of std_logic_vector(7 downto 0);

    constant ZERO_MEMORY : memory_image_t := (others => x"00");

    -- Reference program:
    --   A <- 5; MEM[F0] <- A; A <- MEM[F0]; A <- A + MEM[F0];
    --   MEM[F1] <- A; halt. The expected final bytes are F0=05 and F1=0A.
    constant REFERENCE_PROGRAM : memory_image_t := (
        0  => OPCODE_LDI,
        1  => x"05",
        2  => OPCODE_STA,
        3  => x"F0",
        4  => OPCODE_LDA,
        5  => x"F0",
        6  => OPCODE_ADD,
        7  => x"F0",
        8  => OPCODE_STA,
        9  => x"F1",
        10 => OPCODE_HLT,
        others => x"00"
    );
end package;

package body memory_pkg is
end package body;
