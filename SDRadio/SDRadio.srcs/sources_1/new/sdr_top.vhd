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
use IEEE.NUMERIC_STD.ALL;
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
    
    -- SW[0] for FIR Compiler application
    signal filter_sel : std_logic;
    
    -- signals to/from DAC Interface 
    signal lrclk, bclk, mclk, sdata, latched_data : std_logic;
    signal dac_data_word, filtered, unfiltered : std_logic_vector(31 downto 0);
    signal dds_ready, dds_ready_reg, dds_sample :std_logic_vector(15 downto 0);
    signal dac_data_index_reg : integer range 0 to 31;
    signal dac_data_index : std_logic_vector(31 downto 0);
    signal dds_data_valid : std_logic;
    
    -- signal to/from DDS Compiler
    signal phase_increment, phase_ready : std_logic_vector(31 downto 0);
    signal increment_valid, ps7_reset : std_logic;
    
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
        hdmi_in_ddc_scl_i : in STD_LOGIC;
        hdmi_in_ddc_scl_o : out STD_LOGIC;
        hdmi_in_ddc_scl_t : out STD_LOGIC;
        hdmi_in_ddc_sda_i : in STD_LOGIC;
        hdmi_in_ddc_sda_o : out STD_LOGIC;
        hdmi_in_ddc_sda_t : out STD_LOGIC;
        M_AXIS_0_tvalid : out STD_LOGIC;
        M_AXIS_0_tready : in STD_LOGIC;
        M_AXIS_0_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
        m_axis_aclk_0 : in STD_LOGIC;
        m_axis_aresetn_0 : in STD_LOGIC;
        ps7_reset : out STD_LOGIC);
      end component lab2_proc_system;
      
      -- component for DDS Compiler
      component dds_compiler_0 
        port (
        aclk : IN STD_LOGIC;
        aresetn : IN STD_LOGIC;
        s_axis_phase_tvalid : IN STD_LOGIC;
        s_axis_phase_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
      end component;
      
      -- component for ILA
      component ila_0
        port (
            clk : in std_logic;
            probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
            probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
            probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
            probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
            probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
            probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
            probe6 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
            probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0));
      end component;
begin
    --------------------------------------------
    -------- Intputs for External Pins ---------
    --------------------------------------------
    OBUF_inst1 : OBUF
        port map (
           O => clk,
           I => CLK125MHZ);
           
    resetn <= not(btn(0));
    switches <= sw;
        
    --------------------------------------------
    ------- DAC Interface Implementation -------
    --------------------------------------------
    
    dac_data_word <= filtered when (switches(0) = '1') else unfiltered;
     
    dac_intfc : entity work.lowlevel_dac_intfc(Behavioral) 
                port map (resetn => resetn,
                          clk => clk,
                          data_word => dac_data_word,
                          sdata => sdata,
                          lrclk => lrclk,
                          bclk => bclk,
                          mclk => mclk,
                          index => dac_data_index_reg,
                          latched_data => latched_data);
                          
    --------------------------------------------
    ---- Zynq Process System Implementation ----
    --------------------------------------------
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
      M_AXIS_0_tdata(31 downto 0) => phase_ready,
      M_AXIS_0_tready => '1',
      M_AXIS_0_tvalid => increment_valid,
      hdmi_in_ddc_scl_i => hdmi_in_ddc_scl_i,
      hdmi_in_ddc_scl_o => hdmi_in_ddc_scl_o,
      hdmi_in_ddc_scl_t => hdmi_in_ddc_scl_t,
      hdmi_in_ddc_sda_i => hdmi_in_ddc_sda_i,
      hdmi_in_ddc_sda_o => hdmi_in_ddc_sda_o,
      hdmi_in_ddc_sda_t => hdmi_in_ddc_sda_t,
      m_axis_aclk_0 => clk,
      m_axis_aresetn_0 => resetn,
      ps7_reset => ps7_reset);
      
    --------------------------------------------
    ------- DDS Compiler Implementation --------
    --------------------------------------------
    -- DDS output register
    phase_reg : process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                phase_increment <= (others => '0');
            elsif increment_valid = '1' then
                phase_increment <= phase_ready; -- Only latch stable sample
            end if;
        end if;
    end process;
      
    dds_gen : dds_compiler_0
      port map (
        aclk => clk,
        aresetn => ps7_reset,
        s_axis_phase_tvalid => '1',
        s_axis_phase_tdata => phase_increment,
        m_axis_data_tvalid => dds_data_valid,
        m_axis_data_tdata => dds_ready);
        
    -- DDS output register
    dds_reg : process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                dds_sample <= (others => '0');
            elsif dds_data_valid = '1' then
                if latched_data = '1' then
                    dds_sample <= dds_ready; -- Only latch stable sample
                end if;
            end if;
        end if;
    end process;
    
    -- Combine into full 32-bit word (duplicate for both channels)
    unfiltered <= dds_sample & dds_sample;
    
    --------------------------------------------
    ---------- Filter  Implementation ----------
    --------------------------------------------
    filter_intfc : entity work.filter_design(Behavioral)
        port map ( clk => clk,
                   resetn => resetn,
                   dds_data => dds_ready,
                   dds_valid => dds_data_valid,
                   dac_data => filtered);
                       
    --------------------------------------------
    -------- Outputs for External Pins ---------
    --------------------------------------------
      
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
      ac_sda <= hdmi_in_ddc_sda_io;
      ac_scl <= hdmi_in_ddc_scl_io;
      ac_pbdat <= sdata;
      
    --------------------------------------------
    ------------ ILA Implementation ------------
    --------------------------------------------
   -- dac_data_index <= std_logic_vector(to_unsigned(dac_data_index_reg, 32));
    ila_inst : ila_0
        port map (
            clk => CLK125MHZ,
            probe0 => unfiltered,
            probe1(0) => sdata,
            probe2(0) => lrclk,
            probe3(0) => bclk,
            probe4(0) => ps7_reset,
            probe5(0) => latched_data,
            probe6 => dds_sample,
            probe7 => filtered);  
end Behavioral;
