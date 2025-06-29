library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lowlevel_dac_intfc is
    Port (
        resetn       : in  std_logic;                        -- active low synchronous reset
        clk          : in  std_logic;                        -- 125 MHz clock
        data_word    : in  std_logic_vector(31 downto 0);    -- 32-bit input data
        sdata        : out std_logic;                        -- serial data out to the DAC
        lrclk        : out std_logic;                        -- 50% duty cycle L/R channel select
        bclk         : out std_logic;                        -- bit clock
        mclk         : out std_logic;                        -- master clock (12.5 MHz)
        index        : out integer;
        latched_data : out std_logic                         -- one clk pulse signaling new word was latched
    );
end lowlevel_dac_intfc;

architecture Behavioral of lowlevel_dac_intfc is

    -- Internal latched data register
    signal latched_word  : std_logic_vector(31 downto 0) := (others => '0');

    -- Clocks and control
    signal lrclk_out     : std_logic;
    signal bclk_prev     : std_logic := '0';
    signal bclk_out      : std_logic;
    signal mclk_out      : std_logic;

    -- Bit position tracking
    signal bit_val       : integer range 0 to 31 := 31;

begin

    -- BCLK = 1.5625 MHz --> 125 MHz / (2*1.5625) = 40
    bclk_gen : entity work.clk_divider 
               generic map (MAX => 40)
               port map (clk => clk,
                         resetn => resetn,
                         div => bclk_out);

    -- MCLK = 12.5 MHz --> 125 MHz / (2*12.5) = 5
    mclk_gen : entity work.clk_divider
               generic map (MAX => 5)
               port map (clk => clk,
                         resetn => resetn,
                         div => mclk_out);

    -- LRCLK = ~48.8 kHz --> 125 MHz / (2*48.8kHz) = 1280
    lrclk_gen : entity work.clk_divider 
               generic map (MAX => 1280)
               port map (clk => clk,
                         resetn => resetn,
                         div => lrclk_out);

    -- Main logic for serial output and word latching
    process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                bit_val      <= 31;
                bclk_prev    <= '0';
                latched_data <= '0';
                sdata <= '0';
                latched_word <= (others => '0');
            else
                -- On falling edge of bclk, shift data
                if bclk_prev = '1' and bclk_out = '0' then
                    sdata <= latched_word(bit_val);
                                                         
                    if bit_val = 0 then
                        bit_val      <= 31;    
                        latched_word <= data_word;   -- latch new word
                        latched_data <= '1';         -- signal that new word was latched                    
                    else
                        bit_val      <= bit_val - 1;
                        latched_data <= '0';
                    end if;
                else
                    latched_data <= '0';
                end if;

                bclk_prev <= bclk_out;
            end if;
        end if;
    end process;
       
    -- Assign outputs
    bclk  <= bclk_out;
    mclk  <= mclk_out;
    lrclk <= lrclk_out;
    index <= bit_val;
    
end Behavioral;
