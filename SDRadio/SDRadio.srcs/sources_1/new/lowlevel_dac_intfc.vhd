---------------------------------------------------------------------------------- 
-- Engineer: E. Desir
-- 
-- Create Date: 05/24/2025 12:16:50 PM
-- Module Name: lowlevel_dac_intfc - Behavioral
-- Project Name: Software Defined Radio
-- Target Devices: Zybo Z7 (Zynq - 7020 Development Board)
-- Description: This module respresents a DAC interface which generates 3 clock 
--              signals (LRCLK, BCLK, MCLK), outputs each bit of data_word signal   
--              for DAC starting with bit 31, and asserts a signal indicating when
--              this module is prepared to receive and output new data.  
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lowlevel_dac_intfc is
    Port ( resetn : in std_logic;                        -- active low synchronous reset
           clk : in std_logic;                           -- 125 MHz clock
           data_word : in std_logic_vector(31 downto 0); -- 32 bit input data
           sdata : out std_logic;                        -- serial data out to the DAC
           lrclk : out std_logic;                         -- a 50% duty cycle signal aligned as shown below
           bclk : out std_logic;                         -- the dac clocks sdata on the rising edge of this clock
           mclk : out std_logic;                         -- a 12.5MHz clock with arbitrary phase, runs all the time
           index : out integer;
           latched_data : out std_logic);                -- 1 clk125 wide pulse which indicates when the current
                                                         -- value of data_word has been read by this component
                                                         -- (and can be safely changed)
end lowlevel_dac_intfc;

architecture Behavioral of lowlevel_dac_intfc is
    signal lacthed_word : std_logic_vector(31 downto 0);
    signal lrclk_out, bclk_prev, bclk_out, mclk_out : std_logic;
    signal bit_val : integer range 0 to 31;
begin

    -- BCLK instantiation (125 / 1.5625 MHz / 2)  = 40
    bclk_gen : entity work.clk_divider 
               generic map (MAX => 40)
               port map (clk => clk,
                         resetn => resetn,
                         div => bclk_out);

    -- MCLK instantiation (125 / 12.5 MHz / 2)  = 5
    mclk_gen : entity work.clk_divider
               generic map (MAX => 5)
               port map (clk => clk,
                         resetn => resetn,
                         div => mclk_out);    

    -- LRCLK instantiation (125 / 48.828125 kHz / 2)  = 1280
    lrclk_gen : entity work.clk_divider 
               generic map (MAX => 1280)
               port map (clk => clk,
                         resetn => resetn,
                         div => lrclk_out);

    process (clk)
    begin
        if(rising_edge(clk)) then
            if(resetn = '0') then
                latched_data <= '0';
                bit_val <= 31;
                bclk_prev <= '0';
                sdata <= '0';
            else
                -- At every falling edge of bclk, update the bit_val
                -- and sdata.
                if(bclk_prev = '1' and bclk_out = '0') then  
                    -- Updated sdata will show on next clock cycle
                    -- Displaying the following sequence:
                    -- LRCLK = 0 => Index 31 to 17 or 0
                    -- LRCLK = 1 => Index 16 to 1
                    sdata <= data_word(bit_val);
                    
                    -- When bit_val is 0, assert latched_data so that 
                    -- sdata can output new data when bit_val returns 
                    -- to 31.                                      
                    if (bit_val = 0) then
                        bit_val <= 31;
                        latched_data <= '1';
                    else
                        bit_val <= bit_val - 1;
                        latched_data <= '0';
                    end if;
                else
                    latched_data <= '0';
                end if;
                
                bclk_prev <= bclk_out;  -- to help keep track of falling edges
            end if;
        end if;
    end process;
       
    bclk <= bclk_out;
    mclk <= mclk_out;
    lrclk <= lrclk_out;
    index <= bit_val;
end Behavioral;
