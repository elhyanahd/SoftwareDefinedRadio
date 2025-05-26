library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity lowlevel_dac_intfc_tb is
end;

architecture bench of lowlevel_dac_intfc_tb is

component lowlevel_dac_intfc is 
port (
        resetn                : in std_logic; -- active low synchronous reset
        clk              : in std_logic; -- the clock for all flops in your design
        data_word           : in std_logic_vector(31 downto 0); -- 32 bit input data
        sdata               : out std_logic; -- serial data out to the DAC
        lrclk                : out std_logic;  -- a 50% duty cycle signal aligned as shown below
        bclk                : out std_logic; -- the dac clocks sdata on the rising edge of this clock
        mclk                : out std_logic; -- a 12.5MHz clock output with arbitrary phase
        latched_data        : out std_logic -- 1 clock wide pulse which indicates when you should change data_word
       );
end component;

  signal resetn: std_logic;
  signal clk125: std_logic;
  signal sdata: std_logic;
  signal lrck: std_logic;
  signal bclk: std_logic;
  signal mclk: std_logic;
  signal latched_data: std_logic ;
  signal data_word : std_logic_vector(31 downto 0) := x"8001fffd";

begin

  uut: lowlevel_dac_intfc port map ( resetn       => resetn,
                                     clk       => clk125,
                                     data_word    => data_word,
                                     sdata        => sdata,
                                     lrclk         => lrck,
                                     bclk         => bclk,
                                     mclk         => mclk,
                                     latched_data => latched_data );

  stimulus: process
  begin
    resetn <= '0';
    wait for 10 us;
    resetn <= '1';
    wait;
  end process stimulus;


clkmaker : process
begin
   clk125 <= '0';
   wait for 4 ns;
   clk125 <= '1';
   wait for 4 ns;
end process clkmaker;

data_word <= std_logic_vector(unsigned(data_word)+1) when rising_edge(clk125) and latched_data='1';


end bench;