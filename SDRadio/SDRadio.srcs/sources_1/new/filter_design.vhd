----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/09/2025 05:08:10 PM
-- Module Name: filter_design - Behavioral
-- Project Name: 
-- Target Devices: 
-- Description: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity filter_design is
    Port ( clk : in STD_LOGIC;      -- 125 MHz Clock
           resetn : in STD_LOGIC;   -- asynchronous active-low reset
           --DDS Data Input to Filter
           dds_data : in STD_LOGIC_VECTOR (15 downto 0);
           dds_valid : in STD_LOGIC;
           -- Output of Filter for DAC Interface
           dac_data : out STD_LOGIC_VECTOR (31 downto 0));
end filter_design;

architecture Behavioral of filter_design is
    COMPONENT fir_compiler_125MHz
      PORT (
        aclk : IN STD_LOGIC;
        s_axis_data_tvalid : IN STD_LOGIC;
        s_axis_data_tready : OUT STD_LOGIC;
        s_axis_data_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
    END COMPONENT;
    
    COMPONENT fir_compiler_3MHz
      PORT (
        aclk : IN STD_LOGIC;
        s_axis_data_tvalid : IN STD_LOGIC;
        s_axis_data_tready : OUT STD_LOGIC;
        s_axis_data_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
    END COMPONENT;
    
    signal fir1_data_valid, fir2_data_valid : std_logic;
    signal fir1_data_out, fir2_data_out : std_logic_vector(15 downto 0);
    signal latched_dac_data : std_logic_vector(31 downto 0) := (others => '0');

begin

    --------------------------------------------
    ---------- FIR1  Implementation ------------
    --------------------------------------------
    fir1 : fir_compiler_125MHz
      PORT MAP (
        aclk => clk,
        s_axis_data_tvalid => dds_valid,
        s_axis_data_tready => open,
        s_axis_data_tdata => dds_data,
        m_axis_data_tvalid => fir1_data_valid,
        m_axis_data_tdata => fir1_data_out);
        
    --------------------------------------------
    ---------- FIR2  Implementation ------------
    --------------------------------------------
    fir2 : fir_compiler_3MHz
      PORT MAP (
        aclk => clk,
        s_axis_data_tvalid => fir1_data_valid,
        s_axis_data_tready => open,
        s_axis_data_tdata => fir1_data_out,
        m_axis_data_tvalid => fir2_data_valid,
        m_axis_data_tdata => fir2_data_out);

    --------------------------------------------
    --------- Sending FIR2 Output Data ---------
    --------------------------------------------        
    process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                latched_dac_data <= (others => '0');
            elsif fir2_data_valid = '1' then
                latched_dac_data <= fir2_data_out & fir2_data_out;
            end if;
        end if;
    end process;
    
    dac_data <= latched_dac_data;
end Behavioral;
