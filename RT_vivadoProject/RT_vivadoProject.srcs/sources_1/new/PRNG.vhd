library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Simple 16-bit LFSR based Pseudo-Random Number Generator
-- Taps: 16, 14, 13, 11 (for maximal length sequences)
entity PRNG is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;  -- Asynchronous reset (active high)
        enable     : in  std_logic;  -- Enable state advance
        random_out : out std_logic_vector(15 downto 0)
    );
end PRNG;

architecture Behavioral of PRNG is
    signal lfsr_reg : std_logic_vector(15 downto 0) := x"ACE1"; -- Non-zero initial seed
begin

    process(clk, reset)
        variable feedback : std_logic;
    begin
        if reset = '1' then
            lfsr_reg <= x"ACE1"; -- Reset to initial seed
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Calculate feedback bit (XOR of taps)
                feedback := lfsr_reg(15) xor lfsr_reg(13) xor lfsr_reg(12) xor lfsr_reg(10); 
                -- ^ Taps for 16-bit LFSR: 16,14,13,11 -> indices 15,13,12,10
                -- Shift register and insert feedback
                lfsr_reg <= lfsr_reg(14 downto 0) & feedback;
            end if;
        end if;
    end process;

    -- Output the current LFSR state
    random_out <= lfsr_reg;

end Behavioral;
