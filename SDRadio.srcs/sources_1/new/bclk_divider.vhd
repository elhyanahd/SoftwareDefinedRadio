----------------------------------------------------------------------------------
-- Engineer: E. Desir
-- 
-- Create Date: 05/24/2025 01:48:07 PM
-- Module Name: bclk_divider - Behavioral
-- Project Name: Software Defined Radio
-- Description: This module is used to derive a 1.5625 MHz clock from
--              a 125 MHz clock with a 50% duty cycle. The module uses 
--              a counter which to count to 40 (125 / 1.5625 / 2) and 
--              toggles the BCLK output each time 40 is reached.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity bclk_divider is
    Port ( clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           bclk : out STD_LOGIC);
end bclk_divider;

architecture Behavioral of bclk_divider is
    constant MAX : integer := 40;
    signal counter : integer range 0 to 40;
    signal bclk_out : std_logic;
begin
    process (clk)
    begin
        if (resetn = '0') then
            counter <= 0;
            bclk_out <= '0';
        else
            if(counter = MAX - 1) then
                bclk_out <= not(bclk_out);
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    bclk <= bclk_out;
end Behavioral;
