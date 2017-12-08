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
   Port (StartBme   : in  STD_LOGIC;
         Clk        : in  STD_LOGIC;
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
         DataOutput : out STD_LOGIC_VECTOR (0 to 7);
         LCD        : out STD_LOGIC_VECTOR (0 to 63);
         LCDBlank   : out STD_LOGIC_VECTOR (0 to 15)
   );
end bme280_driver;

architecture Behavioral of bme280_driver is

   type stateType is (idle, memAddr, startDataRead, dataRead, dataDisplay);
   signal state, nextState : stateType;
   signal byteCount    : INTEGER RANGE 0 TO 6 := 0;
   signal address      : STD_LOGIC_VECTOR (0 to 6) := "1010011";
   signal lcdLine      : STD_LOGIC_VECTOR (0 to 63);

begin
--------------------------------------------------------------------------------
-- Clock process
--------------------------------------------------------------------------------
Clock: process(Clk)
begin
   if rising_edge(Clk) then
      if Rst = '1' then
         state <= idle;
      else
         state <= nextState;
      end if;
   end if;
end process Clock;


FSM: process(state, Busy, byteCount, StartBme, address)
begin

   nextState <= state;
   PushFifo <= '0';
   Start <= '0';
   I2cAddress <= address;
   ConTrans <= '0';
   RW <= '0';
   PopFifo <= '0';

   case state is
      when idle =>
         if StartBme = '1' then
            ConTrans <= '1';
            DataOutput <= x"00";
            PushFifo <= '1';
            Start <= '1';
            nextState <= memAddr;
         end if;
      when memAddr =>
         ConTrans <= '1';
         if Busy = '1' then
            PopFifo <= '1';
            nextState <= startDataRead;
         end if;
      when startDataRead =>
         ConTrans <= '1';
         if StartBme = '1' then
            Start <= '1';
            RW <= '1';
            nextState <= dataRead;
         end if;
      when dataRead =>
         RW <= '1';
         ConTrans <= '1';
         if byteCount = 2 then
            ConTrans <= '0';
         end if;
         if Busy = '0' and byteCount = 2 then
            nextState <= dataDisplay;
         end if;
      when dataDisplay =>

   end case;
end process FSM;

DataSentCount: process(Clk, state)
begin
   if rising_edge(Clk) then
      if state = dataRead then
         if DataSent = '1' then
            byteCount <= byteCount + 1;
         end if;
      end if;
   end if;
end process DataSentCount;


LCDProcess: process(Clk, state)
begin
   if rising_edge(Clk) then
      if state = dataDisplay then
         lcdLine <= x"00000000000000" & DataInput;
         LCDBlank <= "0000000000000000";
         LCD <= lcdLine;
      else
         lcdLine  <= x"1111111111111111";
         LCDBlank <= "0000000000000000";
         LCD <= lcdLine;
      end if;
   end if;
end process LCDProcess;

end Behavioral;
