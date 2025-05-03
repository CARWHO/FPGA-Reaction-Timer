library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_controller is
    Port (
        clk           : in  std_logic;
        -- Status inputs
        valid_count   : in  std_logic_vector(1 downto 0);
        show_avg      : in  std_logic;
        show_max      : in  std_logic;
        show_min      : in  std_logic;
        error_detected: in  std_logic;
        -- LED output
        LED           : out std_logic_vector(15 downto 0)
    );
end led_controller;

architecture Behavioral of led_controller is
begin

    ----------------------------------------------------------------------------
    -- LED Status Indicators Process (was section 19)
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- Clear all LEDs by default
            LED <= (others => '0');

            -- Show number of valid times stored (in binary) on LED(1:0)
            LED(1 downto 0) <= valid_count;

            -- Indicate which statistic is being displayed
            if show_avg = '1' then
                LED(4) <= '1';  -- LED 4 for average
            elsif show_max = '1' then
                LED(5) <= '1';  -- LED 5 for maximum
            elsif show_min = '1' then
                LED(6) <= '1';  -- LED 6 for minimum
            end if;

            -- Error indicator
            if error_detected = '1' then
                LED(15) <= '1';  -- LED 15 (rightmost) for error
            end if;
        end if;
    end process;

end Behavioral;
