----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/16/2025 06:50:04 PM
-- Design Name: 
-- Module Name: filter_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity filter_tb is
end filter_tb;

architecture bench of filter_tb is
    component dds_compiler_0 
        port (
        aclk : IN STD_LOGIC;
        aresetn : IN STD_LOGIC;
        s_axis_phase_tvalid : IN STD_LOGIC;
        s_axis_phase_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
    end component;
    
    component filter_design
    Port ( clk : in STD_LOGIC;      -- 125 MHz Clock
           resetn : in STD_LOGIC;   -- asynchronous active-low reset
           --DDS Data Input to Filter
           dds_data : in STD_LOGIC_VECTOR (15 downto 0);
           dds_valid : in STD_LOGIC;
           -- Output of Filter for DAC Interface
           dac_data : out STD_LOGIC_VECTOR (31 downto 0));
    end component;
    
    signal m_axis_data_tvalid, resetn, clk : std_logic := '0';
    signal wave: std_logic_vector(15 downto 0);
    signal phase_in, filtered: std_logic_vector(31 downto 0);
    
    constant freq : integer := 125000000;
    constant desired : integer := 15000;
    constant phase_width : integer := 134217728; --2^27
    constant increment : integer := (desired * phase_width) / freq;
begin

    phase_in <= std_logic_vector(to_signed(increment, 32));

    uut : dds_compiler_0
      port map (
        aclk => clk,
        aresetn => resetn,
        s_axis_phase_tvalid => '1',
        s_axis_phase_tdata => phase_in,
        m_axis_data_tvalid => m_axis_data_tvalid,
        m_axis_data_tdata => wave);
        
    uut2 : filter_design
      port map (
      clk => clk,
      resetn => resetn,
      dds_data => wave,
      dds_valid => m_axis_data_tvalid,
      dac_data => filtered);
        
  stimulus: process
  begin
    resetn <= '0';
    wait for 10 us;
    resetn <= '1';
    wait;
  end process stimulus;

  clkmaker : process
    begin
       clk <= '0';
       wait for 4 ns;
       clk <= '1';
       wait for 4 ns;
    end process clkmaker;

end bench;
