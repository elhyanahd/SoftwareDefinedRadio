----------------------------------------------------------------------------------
-- Engineer: E. Desir
-- 
-- Create Date: 05/24/2025 02:53:03 PM
-- Module Name: dac_intf_tb - Behavioral
-- Project Name: Software Defined Radio
-- Description: This test bench is used to check that sdata outputs the correct
--              assertion that matches the data_word based on a specific bit index.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity dac_intf_tb is
end dac_intf_tb;

architecture Behavioral of dac_intf_tb is
    signal clk : std_logic := '0';
    signal resetn : std_logic := '0';
    
    -- Internal signals for monitoring (exposed from architecture via waveform)
    signal lrclk        : std_logic;
    signal bclk         : std_logic;
    signal mclk         : std_logic;
    signal data_word    : std_logic_vector(31 downto 0) := x"00000000"; 
    signal latched_data, sdata : std_logic;
    signal counter : integer := 2147483647;                 -- can be modified for increment start value
    signal index : integer := 0;
begin

    -- Clock generation: 125 MHz (period = 8 ns)
    clk    <= not clk after 8 ns;    --125MHz clock
    
    -- active-low reset  
    reset : process
	begin
	   wait for 100 ms;
	   resetn <= '1';
	   wait;
	end process;

    -- DUT instantiation
    uut: entity work.lowlevel_dac_intfc(Behavioral)
        port map (resetn => resetn,
                  clk => clk,
                  data_word => data_word,
                  sdata => sdata,
                  lrclk => lrclk,
                  bclk => bclk,
                  mclk => mclk,
                  latched_data => latched_data);

    -- Update data_word only when latched_data is high
    -- Generates data_word value using a counter which increments by 1
    -- after each assertion of latched_data
    update_word : process(clk)
    begin
        if (rising_edge(clk)) then
            if (latched_data = '1') then
                counter <= counter + 1;
                data_word <= std_logic_vector(to_unsigned(counter, 32));
            end if;
        end if;
    end process;
    
    -- Verify that sdata output matches the expected data_word(index) assertion
    word_check : process(bclk)
    begin
        if(rising_edge(bclk)) then
            if(resetn = '0') then
                index <= 31;
            else
                assert data_word(index) = sdata report "The wrong bit value is outputted" severity error;
                
                if(index = 0) then
                    index <= 31;
                else
                    index <= index - 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Verify that bit index matches the specification
    -- LRCLK = 0 => Index 31 to 17 or 0
    -- LRCLK = 1 => Index 16 to 1
    bit_check : process(lrclk)
    begin
        if(lrclk = '0') then
            assert (index > 16 or index = 0) report "Bit index should be between 31 to 17 or 0" severity error;
        else
            assert (index >= 1 and index < 17) report "Bit index should be between 1 to 16" severity error;
        end if;
    end process;
end Behavioral;

