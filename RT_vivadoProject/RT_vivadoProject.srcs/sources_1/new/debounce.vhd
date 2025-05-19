library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce is
    Port (
        clk   : in std_logic;
        rst   : in std_logic;
        noisy : in std_logic;
        clean : out std_logic
    );
end debounce;

architecture Behavioral of debounce is
    -- Adjust DEBOUNCE_COUNT for clock frequency and desired debounce time.
    -- For example, with a 100 MHz clock and ~10 ms debounce, set count = 1,000,000.
    constant DEBOUNCE_COUNT : natural := 1000000;
    signal counter : natural range 0 to DEBOUNCE_COUNT := 0;
    signal state   : std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= '0';
                counter <= 0;
                clean <= '0';
            else
                if noisy = state then
                    counter <= 0;  -- stable reading, reset counter
                else
                    counter <= counter + 1;
                    if counter = DEBOUNCE_COUNT then
                        state <= noisy;
                        clean <= noisy;
                        counter <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;