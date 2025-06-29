----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/25/2025 08:06:05 AM
-- Module Name: buffer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Description: 
-- 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity buffer_reg is
    Port ( clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           latched_data : in STD_LOGIC;
           dds_valid : in STD_LOGIC;
           dds_data : in STD_LOGIC_VECTOR (31 downto 0);
           dac_data_word : out STD_LOGIC_VECTOR (31 downto 0));
end buffer_reg;

architecture Behavioral of buffer_reg is
    type array_mux is array (0 to 3200) of std_logic_vector(31 downto 0);
    signal buff  : array_mux;   
    signal index, counter : integer range 0 to 31 := 0;
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            if (resetn = '0') then
                dac_data_word <= x"00000000";
                counter <= 0;
                index <= 0;
            else
                if(dds_valid = '1') then
                    buff(index) <= dds_data;
                    
                    if(index = 31) then
                        index <= 0;
                    else
                        index <= index + 1;
                    end if;
                end if;

                if(latched_data = '1') then
                    if(counter = 31) then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    dac_data_word <= buff(counter);

end Behavioral;
