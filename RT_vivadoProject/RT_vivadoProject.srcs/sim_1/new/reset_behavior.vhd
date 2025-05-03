library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_reset_behavior is
end tb_reset_behavior;

architecture Behavioral of tb_reset_behavior is

    -- Fast clock for FSM (100 MHz, period = 10 ns)
    signal clk : std_logic := '0';
    -- Slow clock for the counter (for simulation we use a period of 20 ns)
    signal slow_clk : std_logic := '0';
    
    -- Button signals for FSM inputs
    signal btnc, btnr, btnu, btnd, btnl : std_logic := '0';
    
    -- Outputs from your timing_fsm
    signal counter_en, counter_rst, dp_ones, dp_tens, dp_third, show_final : std_logic;
    signal snapshot, error_detected, store_time, clear_times, op_avg, op_min, op_max,
           show_avg, show_min, show_max, use_stats : std_logic;
    
    -- Dummy counter output (e.g., simulating your ones counter)
    signal count : std_logic_vector(3 downto 0) := (others => '0');
    
begin
    ----------------------------------------------------------------------------
    -- Clock generation
    ----------------------------------------------------------------------------
    clk_process: process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;
    
    slow_clk_process: process
    begin
        slow_clk <= '0';
        wait for 10 ns;
        slow_clk <= '1';
        wait for 10 ns;
    end process;
    
    ----------------------------------------------------------------------------
    -- Instantiate the Timing FSM
    ----------------------------------------------------------------------------
    uut: entity work.timing_fsm
        port map (
            clk         => clk,
            btnc        => btnc,
            btnr        => btnr,
            btnu        => btnu,
            btnd        => btnd,
            btnl        => btnl,
            counter_en  => counter_en,
            counter_rst => counter_rst,
            dp_ones     => dp_ones,
            dp_tens     => dp_tens,
            dp_third    => dp_third,
            show_final  => show_final,
            snapshot    => snapshot,
            error_detected => error_detected,
            store_time  => store_time,
            clear_times => clear_times,
            op_avg      => op_avg,
            op_min      => op_min,
            op_max      => op_max,
            show_avg    => show_avg,
            show_min    => show_min,
            show_max    => show_max,
            use_stats   => use_stats
        );
    
    ----------------------------------------------------------------------------
    -- Dummy Counter Process (mimics one of your counters)
    ----------------------------------------------------------------------------
    counter_process: process(slow_clk)
    begin
        if rising_edge(slow_clk) then
            if counter_rst = '1' then
                count <= "0000";
            elsif counter_en = '1' then
                count <= std_logic_vector(unsigned(count) + 1);
            end if;
        end if;
    end process;
    
    ----------------------------------------------------------------------------
    -- Stimulus Process
    ----------------------------------------------------------------------------
    stimulus: process
    begin
        -- Initially, system is in waiting state:
        -- In your FSM "waiting" state, counter_rst should be asserted so the counter resets.
        btnc <= '0'; btnr <= '0'; btnu <= '0'; btnd <= '0'; btnl <= '0';
        wait for 50 ns;
        
        -- Check initial condition: count should be 0.
        assert count = "0000" report "Initial count is not 0" severity note;
        
        ----------------------------------------------------------------------------
        -- Transition to Prompt States:
        ----------------------------------------------------------------------------
        -- Simulate a press on btnc to leave waiting (should go to prompt_1 where reset is held)
        btnc <= '1';
        wait for 10 ns;
        btnc <= '0';
        wait for 50 ns;
        
        -- During the prompt states, counter_rst remains active; count should still be 0.
        assert count = "0000" report "Count did not remain 0 during prompt states" severity note;
        
        ----------------------------------------------------------------------------
        -- Transition to Timing State:
        ----------------------------------------------------------------------------
        -- In your design the FSM waits (T_PROMPT cycles) before transitioning.
        -- For simulation, wait long enough (scaled time) to assume it enters the timing state.
        wait for 200 ns;  -- (Adjust as needed for your simulation)
        
        -- In the timing state, counter_rst is deasserted and counter_en asserted, so the counter should increment.
        wait for 100 ns;
        assert count /= "0000" report "Counter did not increment in timing state" severity note;
        
        ----------------------------------------------------------------------------
        -- Simulate a Reset Transition:
        ----------------------------------------------------------------------------
        -- For example, simulate a button press that returns the FSM to the waiting state.
        -- In your FSM, pressing btnc in display_value returns to waiting.
        btnc <= '1';
        wait for 10 ns;
        btnc <= '0';
        wait for 50 ns;
        
        -- Now the FSM should be in waiting; counter_rst is active and the counter should reset to 0.
        wait for 20 ns;
        assert count = "0000" report "Counter did not reset to 0 when expected" severity error;
        
        wait;
    end process;

end Behavioral;
