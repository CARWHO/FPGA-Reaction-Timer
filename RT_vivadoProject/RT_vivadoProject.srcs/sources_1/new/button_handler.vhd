library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity button_handler is
    Port (
        clk      : in  std_logic;
        btnr     : in  std_logic;  -- Right button (average)
        btnu     : in  std_logic;  -- Up button (max)
        btnd     : in  std_logic;  -- Down button (min)
        btnl     : in  std_logic;  -- Left button (clear)
        
        -- Debounced outputs
        btnr_db  : out std_logic;
        btnu_db  : out std_logic;
        btnd_db  : out std_logic;
        btnl_db  : out std_logic;
        
        -- Edge detection outputs (pulses for one clock cycle on button press)
        btnr_edge : out std_logic;
        btnu_edge : out std_logic;
        btnd_edge : out std_logic;
        btnl_edge : out std_logic
    );
end button_handler;

architecture Behavioral of button_handler is
    -- Debounced button signals
    signal btnr_debounced : std_logic := '0';
    signal btnu_debounced : std_logic := '0';
    signal btnd_debounced : std_logic := '0';
    signal btnl_debounced : std_logic := '0';
    
    -- Previous button states for edge detection
    signal btnr_prev : std_logic := '0';
    signal btnu_prev : std_logic := '0';
    signal btnd_prev : std_logic := '0';
    signal btnl_prev : std_logic := '0';
    
begin
    -- Instantiate debounce circuits for each button
    debounce_btnr : entity work.debounce
        port map (
            clk   => clk,
            rst   => '0',
            noisy => btnr,
            clean => btnr_debounced
        );
        
    debounce_btnu : entity work.debounce
        port map (
            clk   => clk,
            rst   => '0',
            noisy => btnu,
            clean => btnu_debounced
        );
        
    debounce_btnd : entity work.debounce
        port map (
            clk   => clk,
            rst   => '0',
            noisy => btnd,
            clean => btnd_debounced
        );
        
    debounce_btnl : entity work.debounce
        port map (
            clk   => clk,
            rst   => '0',
            noisy => btnl,
            clean => btnl_debounced
        );
    
    -- Edge detection process
    process(clk)
    begin
        if rising_edge(clk) then
            -- Store previous button states
            btnr_prev <= btnr_debounced;
            btnu_prev <= btnu_debounced;
            btnd_prev <= btnd_debounced;
            btnl_prev <= btnl_debounced;
            
            -- Detect rising edges (button presses)
            if btnr_debounced = '1' and btnr_prev = '0' then
                btnr_edge <= '1';
            else
                btnr_edge <= '0';
            end if;
            
            if btnu_debounced = '1' and btnu_prev = '0' then
                btnu_edge <= '1';
            else
                btnu_edge <= '0';
            end if;
            
            if btnd_debounced = '1' and btnd_prev = '0' then
                btnd_edge <= '1';
            else
                btnd_edge <= '0';
            end if;
            
            if btnl_debounced = '1' and btnl_prev = '0' then
                btnl_edge <= '1';
            else
                btnl_edge <= '0';
            end if;
        end if;
    end process;
    
    -- Output debounced button signals
    btnr_db <= btnr_debounced;
    btnu_db <= btnu_debounced;
    btnd_db <= btnd_debounced;
    btnl_db <= btnl_debounced;
    
end Behavioral;
