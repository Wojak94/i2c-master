----------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bme280_driver is
   Port (Start      : in  STD_LOGIC;
         Rst        : in  STD_LOGIC;
         EmptyFifo  : in  STD_LOGIC;
         FullFifo   : in  STD_LOGIC;
         DataInput  : in  STD_LOGIC_VECTOR (0 to 7);
         PushFifo   : out STD_LOGIC;
         PopFifo    : out STD_LOGIC;
         I2cAddress : out STD_LOGIC_VECTOR (0 to 6);
         RW         : out STD_LOGIC;
         DataOutput : out STD_LOGIC_VECTOR (0 to 7)
   );
end bme280_driver;

architecture Behavioral of bme280_driver is

begin


end Behavioral;
