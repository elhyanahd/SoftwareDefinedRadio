----------------------------------------------------------------------------------
-- Engineer: E. Desir
-- 
-- Create Date: 05/24/2025 01:48:07 PM
-- Module Name: lrclk_divider - Behavioral
-- Project Name: Software Defined Radio
-- Description: This module is used to derive a 48.828125 MHz clock from
--              a 125 MHz clock with a 50% duty cycle. The module uses 
--              a counter which to count to 1280 (125 / 48.828125 / 2) and 
--              toggles the LRCLK output each time 1280 is reached.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity lrclk_divider is
    Port ( clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           lrclk : out STD_LOGIC);
end lrclk_divider;

architecture Behavioral of lrclk_divider is
    constant MAX : integer := 1280;
    signal counter : integer range 0 to 1280;
    signal lrclk_out : std_logic;
begin
    process (clk)
    begin
        if(rising_edge(clk))then
            if (resetn = '0') then
                counter <= 0;
                lrclk_out <= '0';
            else
                if(counter = MAX - 1) then
                    lrclk_out <= not(lrclk_out);
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    lrclk <= lrclk_out;
end Behavioral;
