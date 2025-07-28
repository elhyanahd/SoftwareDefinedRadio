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
    
    component dds_compiler_1 
        port (
        aclk : IN STD_LOGIC;
        aresetn : IN STD_LOGIC;
        s_axis_phase_tvalid : IN STD_LOGIC;
        s_axis_phase_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
    end component;
    
    component cmpy_0
      port (
        aclk : IN STD_LOGIC;
        s_axis_a_tvalid : IN STD_LOGIC;
        s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axis_b_tvalid : IN STD_LOGIC;
        s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_dout_tvalid : OUT STD_LOGIC;
        m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(79 DOWNTO 0) 
      );
    end component;
    
    component filter_design
    Port ( clk : in STD_LOGIC;      -- 125 MHz Clock
           resetn : in STD_LOGIC;   -- asynchronous active-low reset
           --DDS Data Input to Filter
           dds_data : in STD_LOGIC_VECTOR (15 downto 0);
           dds_valid : in STD_LOGIC;
           -- Output of Filter 
           dac_data : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    signal adc_valid, complex_valid, resetn, clk, mixed_valid, real_valid, imag_valid: std_logic := '0';
    signal adc_wave, filtered_real, filtered_imag : std_logic_vector(15 downto 0);
    signal phase_in, phase_in2, complex_wave, adc_extended, latched_wave, filtered : std_logic_vector(31 downto 0);
    signal mixed_wave : std_logic_vector(79 downto 0) := (others => '0'); 
    signal latched_mixed_valid : std_logic;
    
    constant freq : integer := 125000000;
    constant desired : integer := 3001000;
    constant desired2 : integer := 3000000;
    constant phase_width : integer := 134217728; --2^27
    constant increment : integer := (desired * phase_width) / freq;
    constant increment2 : integer := (desired2 * phase_width) / freq;
begin

    phase_in <= std_logic_vector(to_signed(increment, 32));
    phase_in2 <= std_logic_vector(to_signed(increment2, 32));

    uut : dds_compiler_0
      port map (
        aclk => clk,
        aresetn => resetn,
        s_axis_phase_tvalid => '1',
        s_axis_phase_tdata => phase_in,
        m_axis_data_tvalid => adc_valid,
        m_axis_data_tdata => adc_wave);
        
    uut2 : dds_compiler_1
      port map (
        aclk => clk,
        aresetn => resetn,
        s_axis_phase_tvalid => '1',
        s_axis_phase_tdata => phase_in2,
        m_axis_data_tvalid => complex_valid,
        m_axis_data_tdata => complex_wave);
        
    adc_extended <= adc_wave & adc_wave;
    uut3 : cmpy_0
      port map (
        aclk => clk,
        s_axis_a_tvalid => adc_valid,
        s_axis_a_tdata => adc_extended,
        s_axis_b_tvalid => complex_valid,
        s_axis_b_tdata => complex_wave,
        m_axis_dout_tvalid => mixed_valid,
        m_axis_dout_tdata => mixed_wave);
        
    latched_wave <= std_logic_vector(shift_right(signed(mixed_wave), 14)(31 downto 0));
    
    uut4 : filter_design
      port map (
      clk => clk,
      resetn => resetn,
      dds_data => latched_wave(31 downto 16),
      dds_valid => mixed_valid,
      dac_data => filtered_imag);
      
    uut5 : filter_design
      port map (
      clk => clk,
      resetn => resetn,
      dds_data => latched_wave(15 downto 0),
      dds_valid => mixed_valid,
      dac_data => filtered_real);
      
    filtered <= filtered_real & filtered_imag;
        
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
