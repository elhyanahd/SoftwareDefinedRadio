----------------------------------------------------------------------------------
-- Engineer: E. Desir
-- 
-- Create Date: 06/01/2025 05:55:20 PM
-- Module Name: wave_generator - Behavioral
-- Project Name: Software Defined Radio
-- Target Devices: Zybo Z7 (Zynq - 7020 Development Board)
-- Description: This module this will create a sinewave (Fs = 48.828kHz, 
--              divided by 8 = 6.103kHz) by outputting each sine wave data
--              point. The data is supplied to the DAC interface and only 
--              changes when lacthed data is high. 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wave_generator is
    Port ( clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           latched_data : in STD_LOGIC;                         -- Asserted by DAC interface for new data
           data_word : out STD_LOGIC_VECTOR (31 downto 0));     -- 32-bit word sent to DAC interface
end wave_generator;

architecture Behavioral of wave_generator is
    signal counter : integer range 0 to 7; 
begin
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (resetn = '0') then
                counter <= 0;
                data_word <= (others=>'0');
            else
                -- Update the counter once latched_data is asserted
                if(latched_data = '1') then
                    if(counter = 7) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                end if;
                
                -- Based on counter value, update data word
                case (counter) is
                    when 0 => data_word <= std_logic_vector(to_signed( 0, 32));
                    when 1 => data_word <= std_logic_vector(to_signed( 7070, 32));
                    when 2 => data_word <= std_logic_vector(to_signed( 10000, 32));
                    when 3 => data_word <= std_logic_vector(to_signed( 7070, 32));
                    when 4 => data_word <= std_logic_vector(to_signed( 0, 32));
                    when 5 => data_word <= std_logic_vector(to_signed( -7070, 32));
                    when 6 => data_word <= std_logic_vector(to_signed( -10000, 32));
                    when 7 => data_word <= std_logic_vector(to_signed( -7070, 32));
                end case;
            end if;
        end if;
    end process;
end Behavioral;
