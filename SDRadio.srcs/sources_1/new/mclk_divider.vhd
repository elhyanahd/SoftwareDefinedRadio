----------------------------------------------------------------------------------
-- Engineer: E. Desir
-- 
-- Create Date: 05/24/2025 01:48:07 PM
-- Module Name: mclk_divider - Behavioral
-- Project Name: Software Defined Radio
-- Description: This module is used to derive a 12.5 MHz clock from
--              a 125 MHz clock with a 50% duty cycle. The module uses 
--              a counter which to count to 5 (125 / 12.5 / 2) and 
--              toggles the MCLK output each time 5 is reached.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mclk_divider is
    Port ( clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           mclk : out STD_LOGIC);
end mclk_divider;

architecture Behavioral of mclk_divider is
    constant MAX : integer := 5;
    signal counter : integer range 0 to 5;
    signal mclk_out : std_logic;
begin
    process (clk)
    begin
        if(rising_edge(clk)) then
            if (resetn = '0') then
                counter <= 0;
                mclk_out <= '0';
            else
                if(counter = MAX - 1) then
                    mclk_out <= not(mclk_out);
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    mclk <= mclk_out;
end Behavioral;
