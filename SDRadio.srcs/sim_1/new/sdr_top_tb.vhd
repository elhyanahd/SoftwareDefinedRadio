----------------------------------------------------------------------------------
-- Engineer: 
-- 
-- Create Date: 05/24/2025 02:53:03 PM
-- Module Name: sdr_top_tb - Behavioral
-- Project Name: Software Defined Radio
-- Description: 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sdr_top_tb is
end sdr_top_tb;

architecture Behavioral of sdr_top_tb is
    signal clk : std_logic := '0';
    signal resetn : std_logic := '1';
    
    -- Internal signals for monitoring (exposed from architecture via waveform)
    signal lrclk        : std_logic;
    signal bclk         : std_logic;
    signal mclk         : std_logic;
    signal data_word    : std_logic_vector(31 downto 0) := x"A0A01010"; 
    signal latched_data, sdata : std_logic;

begin

    -- Clock generation: 125 MHz (period = 8 ns)
    clk    <= not clk after 8 ns;    --125MHz clock
    
    reset : process
	begin
	   wait for 10ns;
	   resetn <= '0';
	   wait for 10ns;
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

end Behavioral;

