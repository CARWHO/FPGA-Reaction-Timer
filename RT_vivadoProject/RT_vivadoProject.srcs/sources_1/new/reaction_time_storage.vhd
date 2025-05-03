library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reaction_time_storage is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;  -- Clear all stored times
        store_trigger : in  std_logic;  -- Trigger to store a new time
        
        -- Input time in BCD format (4 digits)
        time_thousands : in std_logic_vector(3 downto 0);
        time_hundreds  : in std_logic_vector(3 downto 0);
        time_tens      : in std_logic_vector(3 downto 0);
        time_ones      : in std_logic_vector(3 downto 0);
        
        -- Output for all three stored times (for ALU processing)
        time1_thousands : out std_logic_vector(3 downto 0);
        time1_hundreds  : out std_logic_vector(3 downto 0);
        time1_tens      : out std_logic_vector(3 downto 0);
        time1_ones      : out std_logic_vector(3 downto 0);
        
        time2_thousands : out std_logic_vector(3 downto 0);
        time2_hundreds  : out std_logic_vector(3 downto 0);
        time2_tens      : out std_logic_vector(3 downto 0);
        time2_ones      : out std_logic_vector(3 downto 0);
        
        time3_thousands : out std_logic_vector(3 downto 0);
        time3_hundreds  : out std_logic_vector(3 downto 0);
        time3_tens      : out std_logic_vector(3 downto 0);
        time3_ones      : out std_logic_vector(3 downto 0);
        
        -- Number of valid times stored (0-3)
        valid_count    : out std_logic_vector(1 downto 0)
    );
end reaction_time_storage;

architecture Behavioral of reaction_time_storage is
    -- Storage for three reaction times (each 16 bits - 4 BCD digits)
    type time_array is array (0 to 2) of std_logic_vector(15 downto 0);
    signal stored_times : time_array := (others => (others => '0'));
    
    -- Count of valid entries (0-3)
    signal count : unsigned(1 downto 0) := "00";
    
    -- Previous state of store_trigger for edge detection
    signal store_trigger_prev : std_logic := '0';
    
begin
    -- Reverted to synchronous reset
    process(clk) 
    begin
        if rising_edge(clk) then
            -- Store previous trigger state for edge detection first
            store_trigger_prev <= store_trigger;

            -- Check reset condition synchronously
            if reset = '1' then
                -- Synchronous Reset: Clear on next clock edge
                stored_times <= (others => (others => '0'));
                count <= "00";
                -- store_trigger_prev is handled above, no need to reset here
            elsif store_trigger = '1' and store_trigger_prev = '0' then
                -- Rising edge on store_trigger - store new time
                
                -- Shift existing times
                if count > 0 then
                    stored_times(1) <= stored_times(0);
                end if;
                
                if count > 1 then
                    stored_times(2) <= stored_times(1);
                end if;
                
                -- Store new time in position 0
                stored_times(0) <= time_thousands & time_hundreds & time_tens & time_ones;
                
                -- Update count (max 3)
                if count < 3 then
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Output the stored times
    -- Time 1 (most recent)
    time1_thousands <= stored_times(0)(15 downto 12);
    time1_hundreds  <= stored_times(0)(11 downto 8);
    time1_tens      <= stored_times(0)(7 downto 4);
    time1_ones      <= stored_times(0)(3 downto 0);
    
    -- Time 2
    time2_thousands <= stored_times(1)(15 downto 12);
    time2_hundreds  <= stored_times(1)(11 downto 8);
    time2_tens      <= stored_times(1)(7 downto 4);
    time2_ones      <= stored_times(1)(3 downto 0);
    
    -- Time 3 (oldest)
    time3_thousands <= stored_times(2)(15 downto 12);
    time3_hundreds  <= stored_times(2)(11 downto 8);
    time3_tens      <= stored_times(2)(7 downto 4);
    time3_ones      <= stored_times(2)(3 downto 0);
    
    -- Output valid count
    valid_count <= std_logic_vector(count);
    
end Behavioral;
