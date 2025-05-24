----------------------------------------------------------------------------------
-- Engineer: 
-- 
-- Create Date: 05/24/2025 12:16:50 PM
-- Module Name: sdr_top - Behavioral
-- Project Name: Software Defined Radio
-- Target Devices: Zybo Z7 (Zynq - 7020 Development Board)
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sdr_top is
    Port ( CLK125MHZ : in STD_LOGIC;
           SW : in STD_LOGIC_VECTOR(0 downto 0));
end sdr_top;

architecture Behavioral of sdr_top is
    -- input 125 MHz clock signal
    signal clk : std_logic;
    
    -- input SW[0] for resetn 
    signal resetn : std_logic;
    
    -- signals for connection to DAC Interface
    signal lrclk, bclk, mclk, latched_data, sdata : std_logic;
    signal dac_data_in : std_logic_vector(31 downto 0);
begin
    -- connecting external pins to local signals
    clk <= CLK125MHZ;
    resetn <= not(SW(0));
    
    -- Instance of DAC Interface
    dac_intfc : entity work.lowlevel_dac_intfc(Behavioral) 
                port map (resetn => resetn,
                          clk => clk,
                          data_word => dac_data_in,
                          sdata => sdata,
                          lrclk => lrclk,
                          bclk => bclk,
                          mclk => mclk,
                          latched_data => latched_data);
end Behavioral;
