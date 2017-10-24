
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_queue is
   Port (Clk        : in  STD_LOGIC;
         Rst        : in  STD_LOGIC;
         PushFifo   : in  STD_LOGIC;
         PopFifo    : in  STD_LOGIC;
         EmptyFifo  : out STD_LOGIC;
         FullFifo   : out STD_LOGIC;
         DataInput  : in  STD_LOGIC_VECTOR (0 to 7);
         DataOutput : out STD_LOGIC_VECTOR (0 to 7)
        );
end fifo_queue;

architecture Behavioral of fifo_queue is

  type fifoArray is array (0 to 15) of STD_LOGIC_VECTOR (0 to 7);

  signal fifoMemory          : fifoArray;
  signal fifoLooped          : STD_LOGIC := '0';
  signal fifoHead, fifoTail  : INTEGER RANGE 0 TO 15 := 0;
  signal fifoEmpty           : STD_LOGIC := '1';
  signal fifoFull            : STD_LOGIC := '0';

begin
--------------------------------------------------------------------------------
-- Fifo queue process
--------------------------------------------------------------------------------
FifoQueue: process(Clk)
begin
   if rising_edge(Clk) then
      if Rst = '1' then
         fifoHead <= 0;
         fifoTail <= 0;
         fifoEmpty <= '1';
         fifoFull <= '0';
         fifoLooped <= '0';
      else
         DataOutput <= fifoMemory(fifoTail);
         -- Data In
         if PushFifo = '1' and fifoFull = '0' then
            fifoMemory(fifoHead) <= DataInput;
            if fifoHead = 15 then
               fifoHead <= 0;
               fifoLooped <= '1';
            else
               fifoHead <= fifoHead + 1;
            end if;
         end if;
         -- Data Out
         if PopFifo = '1' and fifoEmpty = '0' then
            if fifoTail = 15 then
               fifoTail <= 0;
               fifoLooped <= '0';
            else
               fifoTail <= fifoTail + 1;
            end if;
         end if;
         -- Update empty/full status
         if fifoTail = fifoHead then
            if fifoLooped = '1' then
               fifoFull <= '1';
               FullFifo <= '1';
               fifoEmpty <= '0';
               EmptyFifo <= '0';
            else
               fifoEmpty <= '1';
               EmptyFifo <= '1';
               fifoFull <= '0';
               FullFifo <= '0';
            end if;
         else
            -- Internal signals
            fifoEmpty <= '0';
            fifoFull <= '0';
            -- External signals
            EmptyFifo <= '0';
            FullFifo <= '0';
         end if;
      end if;
   end if;
end process FifoQueue;

end Behavioral;
