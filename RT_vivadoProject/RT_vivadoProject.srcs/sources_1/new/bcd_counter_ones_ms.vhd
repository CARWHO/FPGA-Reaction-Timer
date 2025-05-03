library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This counter counts 1-ms intervals (driven by slow_clk_ms) and outputs a BCD digit.
-- It increments when enabled and rolls over from 9 to 0.
entity Ones_counter is
    Port (
         CLK_1MS  : in  std_logic;                  -- 1 kHz clock input (1 ms period)
         RESET    : in  std_logic;                  -- Active-high synchronous reset
         EN       : in  std_logic;                  -- Enable counting
         COUNT    : out std_logic_vector(3 downto 0); -- 4-bit BCD output (0 to 9)
         ROLLOVER : out std_logic                   -- High for one CLK_1MS cycle when count rolls over
    );
end Ones_counter;

architecture Behavioral of Ones_counter is
    signal count_int : unsigned(3 downto 0) := (others => '0');
begin

    process(CLK_1MS)
    begin
        if rising_edge(CLK_1MS) then
            if RESET = '1' then
                count_int <= (others => '0');
                ROLLOVER  <= '0';
            elsif EN = '1' then
                if count_int = 9 then
                    count_int <= (others => '0');
                    ROLLOVER  <= '1'; -- Rollover asserted for one cycle
                else
                    count_int <= count_int + 1;
                    ROLLOVER  <= '0';
                end if;
            else
                -- Hold count when not enabled, clear rollover
                ROLLOVER <= '0';
            end if;
        end if;
    end process;

    COUNT <= std_logic_vector(count_int);

end Behavioral;
