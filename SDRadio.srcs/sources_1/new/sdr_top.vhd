----------------------------------------------------------------------------------
-- Engineer: E. Desir
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
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity sdr_top is
    Port ( --DOES NOT NEED CONSTRAINTS
            DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
            DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
            DDR_cas_n : inout STD_LOGIC;
            DDR_ck_n : inout STD_LOGIC;
            DDR_ck_p : inout STD_LOGIC;
            DDR_cke : inout STD_LOGIC;
            DDR_cs_n : inout STD_LOGIC;
            DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
            DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
            DDR_odt : inout STD_LOGIC;
            DDR_ras_n : inout STD_LOGIC;
            DDR_reset_n : inout STD_LOGIC;
            DDR_we_n : inout STD_LOGIC;
            FIXED_IO_ddr_vrn : inout STD_LOGIC;
            FIXED_IO_ddr_vrp : inout STD_LOGIC;
            FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
            FIXED_IO_ps_clk : inout STD_LOGIC;
            FIXED_IO_ps_porb : inout STD_LOGIC;
            FIXED_IO_ps_srstb : inout STD_LOGIC;

           -- External Pins
           CLK125MHZ : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR(0 downto 0);
           sw  : in STD_LOGIC_VECTOR(3 downto 0);
           led : out STD_LOGIC_VECTOR(3 downto 0);
           --ac_reclrc : out std_logic;
           ac_muten : out STD_LOGIC;
           ac_bclk : out std_logic;
           ac_mclk : out std_logic;
           ac_scl  : inout std_logic;
           ac_sda  : inout std_logic;
           ac_pbdat : out std_logic;
           ac_pblrc : out std_logic);
end sdr_top;

architecture Behavioral of sdr_top is
    -- input external board pin signals
    signal clk, resetn : std_logic;
    signal switches    : std_logic_vector(3 downto 0);
    
    -- signals from DAC Interface 
    signal lrclk, bclk, mclk, latched_data, sdata : std_logic;
    
    -- signal from Sine Wave Generator
    signal data_word : std_logic_vector(31 downto 0);
    
    -- signals for SCL and SDA IOBUFs 
    signal hdmi_in_ddc_scl_i : STD_LOGIC;
    signal hdmi_in_ddc_scl_o : STD_LOGIC;
    signal hdmi_in_ddc_scl_t : STD_LOGIC;
    signal hdmi_in_ddc_sda_i : STD_LOGIC;
    signal hdmi_in_ddc_sda_o : STD_LOGIC;
    signal hdmi_in_ddc_sda_t : STD_LOGIC;
    signal hdmi_in_ddc_scl_io : STD_LOGIC;
    signal hdmi_in_ddc_sda_io : STD_LOGIC;
    
    -- component for IOBUF
    component IOBUF is
      port (
        I : in STD_LOGIC;
        O : out STD_LOGIC;
        T : in STD_LOGIC;
        IO : inout STD_LOGIC);
    end component IOBUF;
    
    -- component for process system
    component lab2_proc_system is
      port (
        DDR_cas_n : inout STD_LOGIC;
        DDR_cke : inout STD_LOGIC;
        DDR_ck_n : inout STD_LOGIC;
        DDR_ck_p : inout STD_LOGIC;
        DDR_cs_n : inout STD_LOGIC;
        DDR_reset_n : inout STD_LOGIC;
        DDR_odt : inout STD_LOGIC;
        DDR_ras_n : inout STD_LOGIC;
        DDR_we_n : inout STD_LOGIC;
        DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
        DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
        DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
        DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
        DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
        DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
        FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
        FIXED_IO_ddr_vrn : inout STD_LOGIC;
        FIXED_IO_ddr_vrp : inout STD_LOGIC;
        FIXED_IO_ps_srstb : inout STD_LOGIC;
        FIXED_IO_ps_clk : inout STD_LOGIC;
        FIXED_IO_ps_porb : inout STD_LOGIC;
        sws_4bits_tri_i : in STD_LOGIC_VECTOR ( 3 downto 0 );
        leds_4bits_tri_o : out STD_LOGIC_VECTOR ( 3 downto 0 );
        hdmi_in_ddc_scl_i : in STD_LOGIC;
        hdmi_in_ddc_scl_o : out STD_LOGIC;
        hdmi_in_ddc_scl_t : out STD_LOGIC;
        hdmi_in_ddc_sda_i : in STD_LOGIC;
        hdmi_in_ddc_sda_o : out STD_LOGIC;
        hdmi_in_ddc_sda_t : out STD_LOGIC);
      end component lab2_proc_system;
      
      -- component for ILA
      component ila_0
        port (
            clk : in std_logic;
            probe0 : in std_logic_vector(31 downto 0);
            probe1 : in std_logic;
            probe2 : in std_logic;
            probe3 : in std_logic;
            probe4 : in std_logic;
            probe5 : in std_logic;
            probe6 : in std_logic;
            probe7 : in std_logic;
            probe8 : in std_logic;
            probe9 : in std_logic;
            probe10 : in std_logic_vector(3 downto 0));
      end component;
begin
    -- connecting external pins to local signals
    clk <= CLK125MHZ;
    resetn <= not(btn(0));
    
    -- Instance of Sine Wave Generator
    sine_wave : entity work.wave_generator(Behavioral)
                port map (clk => clk,
                          resetn => resetn,
                          latched_data => latched_data,
                          data_word => data_word);
    
    -- Instance of DAC Interface
    dac_intfc : entity work.lowlevel_dac_intfc(Behavioral) 
                port map (resetn => resetn,
                          clk => clk,
                          data_word => data_word,
                          sdata => sdata,
                          lrclk => lrclk,
                          bclk => bclk,
                          mclk => mclk,
                          latched_data => latched_data);
                          
    -- Instance of Zynq Process System
    proc_system : lab2_proc_system
     port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      hdmi_in_ddc_scl_i => hdmi_in_ddc_scl_i,
      hdmi_in_ddc_scl_o => hdmi_in_ddc_scl_o,
      hdmi_in_ddc_scl_t => hdmi_in_ddc_scl_t,
      hdmi_in_ddc_sda_i => hdmi_in_ddc_sda_i,
      hdmi_in_ddc_sda_o => hdmi_in_ddc_sda_o,
      hdmi_in_ddc_sda_t => hdmi_in_ddc_sda_t,
      leds_4bits_tri_o(3 downto 0) => led,
      sws_4bits_tri_i(3 downto 0) => sw);
      
      -- IOBUF instances for SCL and SDA
      scl_iobuf: IOBUF
         port map (
          I => hdmi_in_ddc_scl_o,
          IO => hdmi_in_ddc_scl_io,
          O => hdmi_in_ddc_scl_i,
          T => hdmi_in_ddc_scl_t);
          
     sda_iobuf: IOBUF
         port map (
          I => hdmi_in_ddc_sda_o,
          IO => hdmi_in_ddc_sda_io,
          O => hdmi_in_ddc_sda_i,
          T => hdmi_in_ddc_sda_t);
      
      -- Output to external pins
      ac_muten <= '1';
      ac_bclk <= bclk;
      ac_mclk <= mclk;
      ac_pblrc <= lrclk;
      --ac_reclrc <= lrclk;
      ac_sda <= hdmi_in_ddc_sda_io;
      ac_scl <= hdmi_in_ddc_scl_io;
      ac_pbdat <= sdata;
      
      --ILA Instance
      ila_inst : ila_0
        port map (
            clk => clk,
            probe0 => data_word,
            probe1 => sdata,
            probe2 => lrclk,
            probe3 => bclk,
            probe4 => mclk,
            probe5 => latched_data,
            probe6 => hdmi_in_ddc_scl_o,
            probe7 => hdmi_in_ddc_scl_i,
            probe8 => hdmi_in_ddc_sda_o,
            probe9 => hdmi_in_ddc_sda_i,
            probe10 => sw);  
end Behavioral;
