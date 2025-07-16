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
library xpm;
use xpm.vcomponents.all;

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
    signal clk_3MHz : std_logic;
    
    -- FIR IP variables
    signal fir1_valid_in, fir1_valid_out : std_logic;
    signal fir2_valid_in, fir2_valid_out : std_logic;
    signal fir1_data_in : std_logic_vector(639 downto 0);
    signal fir1_data_out, fir2_data_out : std_logic_vector(15 downto 0);
    signal fir2_data_in : std_logic_vector(1023 downto 0);
    
    -- CDC variables
    signal resetn_sync : std_logic;
    signal fir1_data_sync_out, fir1_data_sync_in : std_logic_vector(15 downto 0);
    signal fir2_data_sync_out, fir2_data_sync_in : std_logic_vector(15 downto 0);
    
    --Shift Register variables
    signal fir1_count      : integer range 0 to 40 := 0;
    signal fir2_count     : integer range 0 to 64 := 0;
    
    COMPONENT fir_compiler_125MHz
      PORT (
        aclk : IN STD_LOGIC;
        s_axis_data_tvalid : IN STD_LOGIC;
        s_axis_data_tready : OUT STD_LOGIC;
        s_axis_data_tdata : IN STD_LOGIC_VECTOR(639 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
    END COMPONENT;
    
    COMPONENT fir_compiler_3MHz
      PORT (
        aclk : IN STD_LOGIC;
        s_axis_data_tvalid : IN STD_LOGIC;
        s_axis_data_tready : OUT STD_LOGIC;
        s_axis_data_tdata : IN STD_LOGIC_VECTOR(1023 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
    END COMPONENT;
    
    component xpm_cdc_sync_rst
      generic (
        -- Common module generics
        DEST_SYNC_FF   : integer := 4;
        INIT           : integer := 1;
        INIT_SYNC_FF   : integer := 0;
        SIM_ASSERT_CHK : integer := 0);
      port (
        src_rst  : in std_logic;
        dest_clk : in std_logic;
        dest_rst : out std_logic);
    end component;
    
    component xpm_cdc_array_single
      generic (
        -- Common module generics
        DEST_SYNC_FF   : integer := 4;
        INIT_SYNC_FF   : integer := 0;
        SIM_ASSERT_CHK : integer := 0;
        SRC_INPUT_REG  : integer := 1;
        WIDTH          : integer := 2 );
      port (
        src_clk  : in std_logic;
        src_in   : in std_logic_vector(WIDTH-1 downto 0);
        dest_clk : in std_logic;
        dest_out : out std_logic_vector(WIDTH-1 downto 0));
    end component;

begin

    -- 3.125 MHz --> 125 MHz / (2*3.125) = 20
    clk_gen : entity work.clk_divider 
               generic map (MAX => 20)
               port map (clk => clk,
                         resetn => resetn,
                         div => clk_3MHz);
                         
    --------------------------------------------
    -------- Resetn CDC Implementation ---------
    --------------------------------------------
    resetn_sync_3MHz : xpm_cdc_sync_rst
            generic map(DEST_SYNC_FF   => 2,
                        INIT           => 1,
                        INIT_SYNC_FF   => 0,
                        SIM_ASSERT_CHK => 0)
            port map (src_rst  => resetn,
                      dest_clk => clk_3MHz,
                      dest_rst => resetn_sync);

    --------------------------------------------
    -------- FIR 1 Input 640-bit Buffer --------
    --------------------------------------------
    -- Process to check whether the store valid dds data
    -- and add to local 640 bit register for FIR input
    -- Once 640 bit data is stored, valid input signal is 
    -- set high
    fir1_input: process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                fir1_count <= 0;
                fir1_valid_in <= '0';
                fir1_data_in <= (others => '0');
            elsif dds_valid = '1' then
                fir1_data_in <= fir1_data_in(623 downto 0) & dds_data;
                fir1_count <= fir1_count + 1;

                if fir1_count = 39 then
                    fir1_valid_in <= '1';
                    fir1_count <= 0;
                else
                    fir1_valid_in <= '0';
                end if;
            end if;
        end if;
    end process;
    
    fir1 : fir_compiler_125MHz
      PORT MAP (
        aclk => clk,
        s_axis_data_tvalid => fir1_valid_in,
        s_axis_data_tready => open,
        s_axis_data_tdata => fir1_data_in,
        m_axis_data_tvalid => fir1_valid_out,
        m_axis_data_tdata => fir1_data_out);
        
    --------------------------------------------
    --  FIR1 24-bit Output CDC Implementation --
    --------------------------------------------                  
    -- Register used to store valid FIR 1 outputs prior
    -- to sending to CDC interface
    fir1_reg : process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                fir1_data_sync_in <= (others => '0');
            elsif fir1_valid_out = '1' then
                fir1_data_sync_in <= fir1_data_out; -- Round/clip 24-bit to 16-bit
            end if;
        end if;
    end process;
    
    fir1_output_sync : xpm_cdc_array_single
        generic map( DEST_SYNC_FF   => 2,
                     INIT_SYNC_FF   => 0,
                     SIM_ASSERT_CHK => 0,
                     SRC_INPUT_REG  => 1,
                     WIDTH          => 16)
        port map (src_clk  => clk,
                  src_in   => fir1_data_sync_in,
                  dest_clk => clk_3MHz,
                  dest_out => fir1_data_sync_out);
        
    --------------------------------------------
    -------- FIR 2 Input 1024-bit Buffer -------
    --------------------------------------------
    -- Process to check whether the store valid FIR 1 data
    -- and add to local 1024 bit register for FIR input
    -- Once 1024 bit data is stored, valid input signal is 
    -- set high
    fir2_buffer : process(clk_3MHz)
    begin
        if rising_edge(clk_3MHz) then
            if resetn_sync = '0' then
                fir2_count <= 0;
                fir2_data_in  <= (others => '0');
                fir2_valid_in <= '0';
            else
                fir2_data_in <= fir2_data_in(1007 downto 0) & fir1_data_sync_out;  
                fir2_count <= fir2_count + 1;

                if fir2_count = 63 then
                    fir2_valid_in <= '1';
                    fir2_count <= 0;
                else
                    fir2_valid_in <= '0';
                end if;
            end if;
        end if;
    end process;
                         
    fir2 : fir_compiler_3MHz
      PORT MAP (
        aclk => clk_3MHz,
        s_axis_data_tvalid => fir2_valid_in,
        s_axis_data_tready => open,
        s_axis_data_tdata => fir2_data_in,
        m_axis_data_tvalid => fir2_valid_out,
        m_axis_data_tdata => fir2_data_out);
        
    --------------------------------------------
    --  FIR2 24-bit Output CDC Implementation --
    --------------------------------------------
    -- Register used to store valid FIR 2 output prior
    -- to sending to CDC interface
    fir2_reg : process(clk_3MHz)
    begin
        if rising_edge(clk_3MHz) then
            if resetn_sync = '0' then
                fir2_data_sync_in <= (others => '0');
            elsif fir2_valid_out = '1' then
                fir2_data_sync_in <= fir2_data_out; -- Round/clip 24-bit to 16-bit
            end if;
        end if;
    end process;
    
    fir2_output_sync : xpm_cdc_array_single
        generic map( DEST_SYNC_FF   => 4,
                     INIT_SYNC_FF   => 0,
                     SIM_ASSERT_CHK => 0,
                     SRC_INPUT_REG  => 1,
                     WIDTH          => 16)
        port map (src_clk  => clk_3MHz,
                  src_in   => fir2_data_sync_in,
                  dest_clk => clk,
                  dest_out => fir2_data_sync_out);
                  
    dac_data <= fir2_data_sync_out & fir2_data_sync_out;
end Behavioral;
