library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
   Port (Address        : in  STD_LOGIC_VECTOR (0 to 6);
         RW             : in  STD_LOGIC;
         Rst            : in  STD_LOGIC;
         Start          : in  STD_LOGIC;
         DataInput      : in  STD_LOGIC_VECTOR (0 to 7);
         DataOutput     : out STD_LOGIC_VECTOR (0 to 7);
         ConTrans       : in  STD_LOGIC; -- Continue transmission signal need to be set within 2,5ns after dataSent
         Clk            : in  STD_LOGIC;
         DataSent       : out STD_LOGIC;
         SDAin          : in  STD_LOGIC;
         SDAout         : out STD_LOGIC;
         SCLin          : in  STD_LOGIC;
         SCLout         : out STD_LOGIC;
         Busy           : out STD_LOGIC;
         NAck           : out STD_LOGIC;
         DataInputFifo  : in  STD_LOGIC_VECTOR (0 to 7);
         DataOutputFifo : out STD_LOGIC_VECTOR (0 to 7);
         PushFifo       : in  STD_LOGIC;
         PopFifo        : in  STD_LOGIC;
         PushInternal   : out STD_LOGIC;
         PopInternal    : out STD_LOGIC;
         EmptyFifo      : in  STD_LOGIC;
         FullFifo       : in  STD_LOGIC
        );
end i2c_master;

architecture Behavioral of i2c_master is

   type stateType is (idle, startTrans, addrTrans, trans, rcvTrans, ack, rcvAck,
                      stopTrans);
   signal state, nextState    : stateType;
   signal clkCount            : UNSIGNED (6 downto 0) := "0000000";
   signal dataCount           : INTEGER RANGE -1 TO 7 := -1;
   signal transDirection      : STD_LOGIC;
   signal addressByte         : STD_LOGIC_VECTOR (0 to 7);
   signal dataRecieved        : STD_LOGIC_VECTOR (7 downto 0);

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
--------------------------------------------------------------------------------
-- State Machine process
--------------------------------------------------------------------------------
FSM: process(state, clkCount, Start, transDirection, dataCount, SDAin, ConTrans,
             EmptyFifo, FullFifo)
begin
   nextState <= state;
   case state is
      when idle =>
         if Start = '1' then
            nextState <= startTrans;
         end if;
      when startTrans =>
         if clkCount = "1111100" then
            nextState <= addrTrans;
         end if;
      when addrTrans =>
         if dataCount = 7 and clkCount = "1111100" then
            nextState <= ack;
         end if;
      when trans =>
         if dataCount = 7 and clkCount = "1111100" then
            nextState <= ack;
         end if;
      when rcvTrans =>
         if dataCount = 7 and clkCount = "1111100" then
            nextState <= rcvAck;
         end if;
      when ack =>
         if clkCount = "1111100" then
            case SDAin is
               when '0' => -- data ACK by slave
                  if ConTrans = '1' and transDirection = '0' then
                     nextState <= trans;
                  elsif ConTrans = '1' and transDirection = '1' then
                     nextState <= rcvTrans;
                  elsif ConTrans = '0' then
                     nextState <= stopTrans;
                  end if;
               when '1' => -- data NACK by slave
                  NAck <= '1';
                  nextState <= stopTrans;
               when others =>
                  nextState <= stopTrans;
            end case;
            if transDirection = '0' and EmptyFifo = '1' then
               nextState <= stopTrans;
            end if;
         end if;
      when rcvAck =>
         if ClkCount = "1111100" then
            if FullFifo = '0' and ConTrans = '1' then
               nextState <= rcvTrans;
            elsif FullFifo = '1' or ConTrans = '0' then
               nextState <= stopTrans;
            end if;
         end if;
      when stopTrans =>
         if clkCount = "1111100" then
            nextState <= idle;
         end if;
   end case;
end process FSM;
--------------------------------------------------------------------------------
-- Fifo queue process
--------------------------------------------------------------------------------
FifoQueue: process(state, Clk, clkCount)
begin
   if rising_edge(Clk) then
      PushInternal <= '0';
      PopInternal <= '0';
      -- Outgoing transmission
      if transDirection = '0' or state = idle then
         if PushFifo = '1' and FullFifo = '0' then
            DataOutputFifo <= DataInput;
            PushInternal <= '1';
         end if;
         if state = trans then
            if clkCount = "1111100" and dataCount = 7 then
              PopInternal <= '1';
            end if;
         end if;
      end if;
      -- Incomming transmission
      if transDirection = '1' or state = idle then
         DataOutput <= DataInputFifo;
         if PopFifo = '1' and EmptyFifo = '0' then
            PopInternal <= '1';
         end if;
         if state = rcvTrans then
            if clkCount = "1111100" and dataCount = 7 then
               DataOutputFifo <= dataRecieved;
               PushInternal <= '1';
            end if;
         end if;
      end if;
   end if;
end process FifoQueue;
--------------------------------------------------------------------------------
-- SDAout signal driver
--------------------------------------------------------------------------------
SdaDriver: process(state, clkCount, Clk, dataCount)
begin
   if rising_edge(Clk) then
      if state = idle then
         SDAout <= '1';
      end if;
      if state = startTrans then
         SDAout <= '0';
      end if;
      if state = addrTrans then
         if clkCount = "0100011" then
            SDAout <= addressByte(dataCount);
         end if;
      end if;
      if state = trans then
         if clkCount = "0100011" then
            SDAout <= DataInputFifo(dataCount);
         end if;
      end if;
      if state = rcvTrans then
         SDAout <= '1';
      end if;
      if state = ack then
         if clkCount = "0001100" then
            SDAout <= '1';
         end if;
      end if;
      if state = rcvAck then
         if clkCount = "0001100" then --ConTrans must be in '0' for the rest of the rcvAck state
            if FullFifo = '1' or ConTrans = '0' then
               SDAout <= '1';
            else
               SDAout <= '0';
            end if;
         end if;
      end if;
      if state = stopTrans then
         if clkCount = "0000000" then
            SDAout <= '0';
         end if;
         if clkCount = "1111100" then
            SDAout <= '1';
         end if;
      end if;
   end if;
end process SdaDriver;
--------------------------------------------------------------------------------
-- SDAin signal driver
--------------------------------------------------------------------------------
SdaInDriver: process(state, clkCount, Clk, dataCount)
begin
   if rising_edge(Clk) then
      if state = rcvTrans then
         if clkCount = "1100000" then
            dataRecieved(7 - dataCount) <= SDAin;
         end if;
      end if;
   end if;
end process SdaInDriver;
--------------------------------------------------------------------------------
-- Scl driver process
--------------------------------------------------------------------------------
SclDriver: process(state, Clk, clkCount)
begin
   if rising_edge(Clk) then
      if state = idle then
         SCLout <= '1';
      end if;
      if state = startTrans then
         if clkCount = "1111100" then
            SCLout <= '0';
         end if;
      end if;
      if state = trans or state = addrTrans or state = rcvTrans
            or state = ack or state = rcvAck then
         if clkCount = "1001000" then
            SCLout <= '1';
         end if;
         if clkCount = "1111100" then
            SCLout <= '0';
         end if;
      end if;
      if state = stopTrans then
         if clkCount = "1001000" then
            SCLout <= '1';
         end if;
      end if;
   end if;
end process SclDriver;
--------------------------------------------------------------------------------
-- Ack process
--------------------------------------------------------------------------------
WaitAck: process(state, clkCount, Clk)
begin
   if rising_edge(Clk) then
      if state = Ack or state = rcvAck then
         if clkCount = "0000000" then
            dataSent <= '1';
         else
            dataSent <= '0';
         end if;
      else
         dataSent <= '0';
      end if;
   end if;
end process WaitAck;
--------------------------------------------------------------------------------
-- Latch for Input Data process
--------------------------------------------------------------------------------
InputLatch: process(Clk, Start, state, Address, RW)
begin
   if rising_edge(Clk) then
      if Start = '1' and state = idle then
         transDirection <= RW;
         addressByte <= Address & RW;
      end if;
   end if;
end process InputLatch;
--------------------------------------------------------------------------------
-- Counter of bits sent
--------------------------------------------------------------------------------
DataCounter: process(state, Clk, clkCount)
begin
   if rising_edge(Clk) then
      if state = startTrans or state = ack or state = rcvAck then
         dataCount <= -1;
      end if;
      if (state = addrTrans or state = trans or state = rcvTrans)
            and clkCount = "00000000" then
         dataCount <= dataCount + 1;
      end if;
   end if;
end process DataCounter;
--------------------------------------------------------------------------------
-- Clock Counter process (0-124 clock ticks)
--------------------------------------------------------------------------------
ClockCounter: process(Clk, Rst, state)
begin
   if rising_edge(Clk) then
      if Rst = '1' or state = idle then
         clkCount <= "0000000";
      else
         if clkCount = "1111100" then
            clkCount <= "0000000";
         else
            clkCount <= clkCount + 1;
         end if;
      end if;
   end if;
end process ClockCounter;
--------------------------------------------------------------------------------
-- Busy signal driver
--------------------------------------------------------------------------------
BusyDriver: process(Clk, state)
begin
   if rising_edge(Clk) then
      if state = idle then
         Busy <= '0';
      else
         Busy <= '1';
      end if;
   end if;
end process BusyDriver;

end Behavioral;
