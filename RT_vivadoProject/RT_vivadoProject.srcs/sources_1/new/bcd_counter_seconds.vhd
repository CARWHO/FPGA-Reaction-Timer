library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This counter represents the thousands-of-ms (seconds) digit.
-- It increments when enabled (EN='1') on the rising edge of INC_TICK.
-- Clocked by the main system clock (CLK).
entity Thousands_Counter is
    port (
        CLK       : in  std_logic;     -- Main system clock (e.g., 100MHz)
        RESET     : in  std_logic;     -- Active-high synchronous reset
        EN        : in  std_logic;     -- Enable counting
        INC_TICK  : in  std_logic;     -- Increment trigger (rollover from previous stage)
        COUNT     : out std_logic_vector(3 downto 0); -- 4-bit BCD output (0 to 9)
        ROLLOVER  : out std_logic      -- High for one CLK cycle on rollover (optional, currently unused)
    );
end Thousands_Counter;

architecture Behavioral of Thousands_Counter is
    signal r_count  : unsigned(3 downto 0) := (others => '0');
    signal inc_prev : std_logic := '0'; -- Previous state of INC_TICK for edge detection
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            -- Register previous INC_TICK state
            inc_prev <= INC_TICK;

            if RESET = '1' then
                r_count  <= (others => '0');
                ROLLOVER <= '0';
                inc_prev <= '0'; -- Reset edge detector state as well
            else
                -- Default ROLLOVER to '0' unless condition met
                ROLLOVER <= '0';
                -- Check for enable and rising edge of INC_TICK
                if EN = '1' and INC_TICK = '1' and inc_prev = '0' then
                    if r_count = 9 then
                        r_count  <= (others => '0');
                        ROLLOVER <= '1'; -- Rollover asserted for one cycle
                    else
                        r_count <= r_count + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    COUNT <= std_logic_vector(r_count);

end Behavioral;
