--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    16:30:41 09/27/2017
-- Design Name:
-- Module Name:    bme280_driver - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bme280_driver is
   Port (Clk        : in  STD_LOGIC;
         Busy       : in  STD_LOGIC;
         Rst        : in  STD_LOGIC;
         EmptyFifo  : in  STD_LOGIC;
         FullFifo   : in  STD_LOGIC;
         DataSent   : in  STD_LOGIC;
         DataInput  : in  STD_LOGIC_VECTOR (0 to 7);
         Start      : out STD_LOGIC;
         ConTrans   : out STD_LOGIC;
         PushFifo   : out STD_LOGIC;
         PopFifo    : out STD_LOGIC;
         I2cAddress : out STD_LOGIC_VECTOR (0 to 6);
         RW         : out STD_LOGIC;
         DataOutput : out STD_LOGIC_VECTOR (0 to 7)
   );
end bme280_driver;

architecture Behavioral of bme280_driver is
   signal address  : STD_LOGIC_VECTOR (0 to 6) := "1110110";
   signal stateNum : INTEGER RANGE 0 TO 4 := 0;

begin

Test: process(Clk, stateNum, Busy, DataSent)
begin
   if rising_edge(Clk) then
      if stateNum = 0 and Busy = '0' then
         I2cAddress <= address;
         RW <= '0';
         ConTrans <= '1';
         DataOutput <= x"F4";
         PushFifo <= '1';
         stateNum <= stateNum + 1;
         Start <= '1';
      elsif stateNum = 1 and Busy = '1' then
         RW <= '1';
         stateNum <= stateNum + 1;
      elsif stateNum = 2 and Busy = '0' then
         Start <= '1';
         stateNum <= stateNum + 1;
      elsif stateNum = 3 and DataSent = '1' then
         stateNum <= stateNum + 1;
      elsif stateNum = 4 and DataSent = '1' then
         ConTrans <= '0';
      else
         PushFifo <= '0';
         Start <= '0';
      end if;
   end if;
end process Test;

end Behavioral;
