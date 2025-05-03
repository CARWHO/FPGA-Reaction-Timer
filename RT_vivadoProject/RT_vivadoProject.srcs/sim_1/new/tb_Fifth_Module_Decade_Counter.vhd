library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Tens_Counter is
-- No port map in a test bench's entity
end tb_Tens_Counter;

architecture TB of tb_Tens_Counter is

    -- Component declaration (if needed in older VHDL styles)
    component Tens_Counter is
        port (
            EN        : in  std_logic;
            RESET     : in  std_logic;
            INCREMENT : in  std_logic;
            COUNT     : out std_logic_vector(3 downto 0);
            TICK      : out std_logic
        );
    end component;

    -- Test signals
    signal s_EN        : std_logic := '0';
    signal s_RESET     : std_logic := '0';
    signal s_INCREMENT : std_logic := '0';
    signal s_COUNT     : std_logic_vector(3 downto 0);
    signal s_TICK      : std_logic;

    -- Simulation constants
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    UUT: Tens_Counter
        port map(
            EN        => s_EN,
            RESET     => s_RESET,
            INCREMENT => s_INCREMENT,
            COUNT     => s_COUNT,
            TICK      => s_TICK
        );

    -- Clock generation for INCREMENT
    p_clk_gen: process
    begin
        while TRUE loop
            s_INCREMENT <= '0';
            wait for CLK_PERIOD/2;
            s_INCREMENT <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -- Stimulus process
    p_stimulus: process
    begin
        -- Initial condition: Deassert reset, disable EN
        s_RESET <= '0';
        s_EN    <= '0';
        wait for 20 ns;

        -- Assert reset for a few cycles
        s_RESET <= '1';
        wait for 20 ns;
        s_RESET <= '0';
        wait for 20 ns;

        -- Enable counting
        s_EN <= '1';
        wait for 100 ns;

        -- Disable counting for a while
        s_EN <= '0';
        wait for 50 ns;

        -- Re-enable counting again
        s_EN <= '1';
        wait for 120 ns;

        -- Finish simulation
        wait;
    end process;

end TB;
