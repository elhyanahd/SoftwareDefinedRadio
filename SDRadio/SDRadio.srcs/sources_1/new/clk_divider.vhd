----------------------------------------------------------------------------------
-- Engineer: E. Desir
-- 
-- Create Date: 05/24/2025 01:48:07 PM
-- Module Name: clk_divider - Behavioral
-- Project Name: Software Defined Radio
-- Description: This module is used to derive a new MHz clock from
--              a 125 MHz clock with a 50% duty cycle. The module uses 
--              a counter which to count to given generic value and 
--              toggles the DIV output each time generic value is reached.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity clk_divider is
    Generic ( MAX : integer := 40 );
    Port ( clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           div : out STD_LOGIC);
end clk_divider;

architecture Behavioral of clk_divider is
    signal counter : integer range 0 to 1280;
    signal clk_out : std_logic;
begin
    process (clk)
    begin
        if(rising_edge(clk)) then
            if (resetn = '0') then
                counter <= 0;
                clk_out <= '0';
            else
                if(counter = MAX - 1) then
                    clk_out <= not(clk_out);
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    div <= clk_out;
end Behavioral;
