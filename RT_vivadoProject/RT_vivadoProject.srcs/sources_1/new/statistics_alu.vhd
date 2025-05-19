library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity statistics_alu is
    Port (
        clk            : in  std_logic;
        
        -- Input times in BCD format
        time1_thousands : in std_logic_vector(3 downto 0);
        time1_hundreds  : in std_logic_vector(3 downto 0);
        time1_tens      : in std_logic_vector(3 downto 0);
        time1_ones      : in std_logic_vector(3 downto 0);
        
        time2_thousands : in std_logic_vector(3 downto 0);
        time2_hundreds  : in std_logic_vector(3 downto 0);
        time2_tens      : in std_logic_vector(3 downto 0);
        time2_ones      : in std_logic_vector(3 downto 0);
        
        time3_thousands : in std_logic_vector(3 downto 0);
        time3_hundreds  : in std_logic_vector(3 downto 0);
        time3_tens      : in std_logic_vector(3 downto 0);
        time3_ones      : in std_logic_vector(3 downto 0);
        
        -- Number of valid times (0-3)
        valid_count    : in std_logic_vector(1 downto 0);
        
        -- Operation select
        op_avg         : in std_logic;  -- Calculate average
        op_min         : in std_logic;  -- Find minimum
        op_max         : in std_logic;  -- Find maximum
        
        -- Result output in BCD
        result_thousands : out std_logic_vector(3 downto 0);
        result_hundreds  : out std_logic_vector(3 downto 0);
        result_tens      : out std_logic_vector(3 downto 0);
        result_ones      : out std_logic_vector(3 downto 0);
        
        -- Indicates if result is valid
        result_valid     : out std_logic
    );
end statistics_alu;

architecture Behavioral of statistics_alu is
    -- Convert BCD to binary for calculations
function bcd_to_binary(
    bcd_thousands, bcd_hundreds, bcd_tens, bcd_ones : std_logic_vector(3 downto 0)
) return unsigned is

    variable thousands_val : unsigned(13 downto 0);
    variable hundreds_val  : unsigned(13 downto 0);
    variable tens_val      : unsigned(13 downto 0);
    variable ones_val      : unsigned(13 downto 0);
    variable binary        : unsigned(13 downto 0);
begin
    -- Multiply nibble by 1000, 100, 10, etc. safely using integer conversion
    thousands_val := to_unsigned(
                        to_integer(unsigned(bcd_thousands)) * 1000, 
                        14
                     );
    hundreds_val  := to_unsigned(
                        to_integer(unsigned(bcd_hundreds)) * 100,  
                        14
                     );
    tens_val      := to_unsigned(
                        to_integer(unsigned(bcd_tens)) * 10,      
                        14
                     );
    ones_val      := to_unsigned(
                        to_integer(unsigned(bcd_ones)),          
                        14
                     );

    -- Now add all four partial values (all are 14 bits wide)
    binary := thousands_val + hundreds_val + tens_val + ones_val;
    return binary;
end function;
    
    -- Convert binary back to BCD using the Double Dabble algorithm
    procedure binary_to_bcd(
        binary : in unsigned(13 downto 0);
        signal bcd_thousands : out std_logic_vector(3 downto 0);
        signal bcd_hundreds : out std_logic_vector(3 downto 0);
        signal bcd_tens : out std_logic_vector(3 downto 0);
        signal bcd_ones : out std_logic_vector(3 downto 0)
    ) is
        variable temp : unsigned(13 downto 0);
        variable bcd : unsigned(15 downto 0) := (others => '0');
    begin
        temp := binary;
        
        -- Double dabble algorithm
        for i in 0 to 13 loop
            -- Check if any BCD digit is >= 5
            if bcd(3 downto 0) > 4 then
                bcd(3 downto 0) := bcd(3 downto 0) + 3;
            end if;
            if bcd(7 downto 4) > 4 then
                bcd(7 downto 4) := bcd(7 downto 4) + 3;
            end if;
            if bcd(11 downto 8) > 4 then
                bcd(11 downto 8) := bcd(11 downto 8) + 3;
            end if;
            if bcd(15 downto 12) > 4 then
                bcd(15 downto 12) := bcd(15 downto 12) + 3;
            end if;
            
            -- Shift left
            bcd := bcd(14 downto 0) & temp(13);
            temp := temp(12 downto 0) & '0';
        end loop;
        
        bcd_thousands <= std_logic_vector(bcd(15 downto 12));
        bcd_hundreds <= std_logic_vector(bcd(11 downto 8));
        bcd_tens <= std_logic_vector(bcd(7 downto 4));
        bcd_ones <= std_logic_vector(bcd(3 downto 0));
    end procedure;
    
    -- Signals for binary representation of times
    signal time1_binary, time2_binary, time3_binary : unsigned(13 downto 0);
    
    -- Signal for result in binary
    signal result_binary : unsigned(13 downto 0);
    
    -- Internal signals for operation results
    signal avg_result, min_result, max_result : unsigned(13 downto 0);
    
    -- Signals for division by 3
    signal sum_times : unsigned(15 downto 0);
    signal div_by_3_result : unsigned(13 downto 0);
    
begin
    -- Convert BCD inputs to binary for calculations
    time1_binary <= bcd_to_binary(time1_thousands, time1_hundreds, time1_tens, time1_ones);
    time2_binary <= bcd_to_binary(time2_thousands, time2_hundreds, time2_tens, time2_ones);
    time3_binary <= bcd_to_binary(time3_thousands, time3_hundreds, time3_tens, time3_ones);
    
    -- Calculate minimum
    process(time1_binary, time2_binary, time3_binary, valid_count)
    begin
        -- Default to first time
        min_result <= time1_binary;
        
        case valid_count is
            when "00" =>
                -- No valid times
                min_result <= (others => '0');
            when "01" =>
                -- Only one time
                min_result <= time1_binary;
            when "10" =>
                -- Two times
                if time2_binary < time1_binary then
                    min_result <= time2_binary;
                else
                    min_result <= time1_binary;
                end if;
            when others =>
                -- Three times
                if time1_binary <= time2_binary and time1_binary <= time3_binary then
                    min_result <= time1_binary;
                elsif time2_binary <= time1_binary and time2_binary <= time3_binary then
                    min_result <= time2_binary;
                else
                    min_result <= time3_binary;
                end if;
        end case;
    end process;
    
    -- Calculate maximum
    process(time1_binary, time2_binary, time3_binary, valid_count)
    begin
        -- Default to first time
        max_result <= time1_binary;
        
        case valid_count is
            when "00" =>
                -- No valid times
                max_result <= (others => '0');
            when "01" =>
                -- Only one time
                max_result <= time1_binary;
            when "10" =>
                -- Two times
                if time2_binary > time1_binary then
                    max_result <= time2_binary;
                else
                    max_result <= time1_binary;
                end if;
            when others =>
                -- Three times
                if time1_binary >= time2_binary and time1_binary >= time3_binary then
                    max_result <= time1_binary;
                elsif time2_binary >= time1_binary and time2_binary >= time3_binary then
                    max_result <= time2_binary;
                else
                    max_result <= time3_binary;
                end if;
        end case;
    end process;
    
    -- Calculate sum for average
    process(time1_binary, time2_binary, time3_binary, valid_count)
    begin
        case valid_count is
            when "00" =>
                -- No valid times
                sum_times <= (others => '0');
            when "01" =>
                -- Only one time
                sum_times <= "00" & time1_binary;
            when "10" =>
                -- Two times
                sum_times <= ("00" & time1_binary) + ("00" & time2_binary);
            when others =>
                -- Three times
                sum_times <= ("00" & time1_binary) + ("00" & time2_binary) + ("00" & time3_binary);
        end case;
    end process;
    
    -- Calculate average
    process(sum_times, valid_count)
    begin
        case valid_count is
            when "00" =>
                -- No valid times
                avg_result <= (others => '0');
            when "01" =>
                -- Only one time (no division needed)
                avg_result <= sum_times(13 downto 0);
            when "10" =>
                -- Two times (divide by 2 = shift right by 1)
                avg_result <= sum_times(14 downto 1);
            when others =>
                -- Three times (divide by 3 using integer division)
                -- The sum_times is 16 bits, but individual times are 14 bits.
                -- Max sum of 3 times (each max 9999) is 29997.
                -- The result of division by 3 will fit in 14 bits.
                avg_result <= sum_times(13 downto 0) / 3; -- Integer division
            end case;
    end process;
    
    -- Select result based on operation
    process(clk)
    begin
        if rising_edge(clk) then
            if op_avg = '1' then
                result_binary <= avg_result;
                if unsigned(valid_count) > 0 then
                    result_valid <= '1';
                else
                    result_valid <= '0';
                end if;
            elsif op_min = '1' then
                result_binary <= min_result;
                if unsigned(valid_count) > 0 then
                    result_valid <= '1';
                else
                    result_valid <= '0';
                end if;
            elsif op_max = '1' then
                result_binary <= max_result;
                if unsigned(valid_count) > 0 then
                    result_valid <= '1';
                else
                    result_valid <= '0';
                end if;
            else
                -- No operation selected, clear result
                result_binary <= (others => '0');
                result_valid <= '0';
            end if;
        end if;
    end process;
    
    -- Convert result to BCD
    binary_to_bcd(result_binary, result_thousands, result_hundreds, result_tens, result_ones);
    
end Behavioral;
