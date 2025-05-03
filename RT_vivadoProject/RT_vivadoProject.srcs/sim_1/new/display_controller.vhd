library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Display_Controller_ms is
    -- Test bench has no ports
end tb_Display_Controller_ms;

architecture Behavioral of tb_Display_Controller_ms is

    -- Component declaration for the Unit Under Test (UUT)
    component Display_Controller_ms is
        generic (
            -- For a 100 MHz clock, MS_UPPERBOUND defines the slow clock period.
            MS_UPPERBOUND : std_logic_vector(27 downto 0) := x"00061A8"
        );
        port (
            CLK100MHZ : in  std_logic;
            BTNC      : in  std_logic;
            BTNR      : in  std_logic;
            BTNU      : in  std_logic;
            BTND      : in  std_logic;
            BTNL      : in  std_logic;
            AN        : out std_logic_vector(7 downto 0);
            CA        : out std_logic;
            CB        : out std_logic;
            CC        : out std_logic;
            CD        : out std_logic;
            CE        : out std_logic;
            CF        : out std_logic;
            CG        : out std_logic;
            DP        : out std_logic;
            LED       : out std_logic_vector(15 downto 0)
        );
    end component;
    
    -- Signals to drive inputs and capture outputs
    signal CLK100MHZ : std_logic := '0';
    signal BTNC      : std_logic := '0';
    signal BTNR      : std_logic := '0';
    signal BTNU      : std_logic := '0';
    signal BTND      : std_logic := '0';
    signal BTNL      : std_logic := '0';
    
    signal AN        : std_logic_vector(7 downto 0);
    signal CA, CB, CC, CD, CE, CF, CG, DP : std_logic;
    signal LED       : std_logic_vector(15 downto 0);

    -- Constant for simulation delay to mimic T_PROMPT in the FSM.
    -- (The real T_PROMPT is 100,000,000 clock cycles, or ~1 sec at 100 MHz.)
    constant T_PROMPT_time : time := 1 sec;
    
begin

    -- Instantiate the Unit Under Test (UUT)
    uut: Display_Controller_ms
        port map (
            CLK100MHZ => CLK100MHZ,
            BTNC      => BTNC,
            BTNR      => BTNR,
            BTNU      => BTNU,
            BTND      => BTND,
            BTNL      => BTNL,
            AN        => AN,
            CA        => CA,
            CB        => CB,
            CC        => CC,
            CD        => CD,
            CE        => CE,
            CF        => CF,
            CG        => CG,
            DP        => DP,
            LED       => LED
        );
        
    ---------------------------------------------------------------------------
    -- Clock Generation Process (100 MHz, 10 ns period)
    ---------------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            CLK100MHZ <= '0';
            wait for 5 ns;
            CLK100MHZ <= '1';
            wait for 5 ns;
        end loop;
    end process;
    
    ---------------------------------------------------------------------------
    -- Stimulus Process: Drives button inputs to traverse all FSM states.
    ---------------------------------------------------------------------------
    stim_proc: process
    begin
        -- --- Initial Conditions ---
        BTNC <= '0';
        BTNR <= '0';
        BTNU <= '0';
        BTND <= '0';
        BTNL <= '0';
        
        wait for 100 ns;  -- allow time for global reset
        
        -- === 1. From Waiting to Prompt_1 ===
        -- Pulse BTNC to start the test (should cause a transition from waiting to prompt_1)
        BTNC <= '1';
        wait for 10 ns;  -- pulse for one clock cycle
        BTNC <= '0';
        
        -- --- Now in prompt_1 state ---
        wait for T_PROMPT_time;  -- wait ~1 sec so FSM advances to prompt_2
        
        -- --- In prompt_2 state ---
        wait for T_PROMPT_time;  -- wait another 1 sec so FSM advances to prompt_3
        
        -- --- In prompt_3 state ---
        wait for T_PROMPT_time;  -- wait 1 sec for FSM to transition from prompt_3 to timing
        
        -- === 2. Timing State ===
        -- At this point the FSM should have entered the timing state.
        -- Let the counter run for a little while (e.g. 200 ms) so you can observe the count.
        wait for 200 ms;
        
        -- === 3. Capture Reaction Time ===
        -- Simulate a reaction by pulsing BTNC in the timing state.
        BTNC <= '1';
        wait for 10 ns;
        BTNC <= '0';
        
        -- --- In display_clear state ---
        wait for T_PROMPT_time;  -- wait 1 sec so FSM advances to display_value
        
        -- --- In display_value state ---
        wait for 100 ms;  -- observe the displayed value
        
        -- === 4. Move to Statistics Displays ===
        -- Pulse BTNR for average display.
        BTNR <= '1';
        wait for 10 ns;
        BTNR <= '0';
        wait for 500 ms;  -- observe average display
        
        -- Pulse BTNU for maximum display.
        BTNU <= '1';
        wait for 10 ns;
        BTNU <= '0';
        wait for 500 ms;  -- observe maximum display
        
        -- Pulse BTND for minimum display.
        BTND <= '1';
        wait for 10 ns;
        BTND <= '0';
        wait for 500 ms;  -- observe minimum display
        
        -- === 5. Clear Statistics and Return to Waiting ===
        -- Pulse BTNL to clear stored times and return the FSM to waiting.
        BTNL <= '1';
        wait for 10 ns;
        BTNL <= '0';
        wait for 500 ms;
        
        -- === 6. Generate an Error Condition ===
        -- Begin a new cycle by pulsing BTNC to start prompt_1 again.
        BTNC <= '1';
        wait for 10 ns;
        BTNC <= '0';
        wait for 500 ms;  -- now in prompt_1
        -- Now press BTNC prematurely in prompt_1 to trigger error_state.
        BTNC <= '1';
        wait for 10 ns;
        BTNC <= '0';
        wait for T_PROMPT_time;  -- wait for error_state to be processed
        
        -- End simulation after allowing time for observation.
        wait for 1 sec;
        assert false report "End of simulation" severity failure;
    end process;

end Behavioral;
