--file: vgatest.vhd
--Authors: William Putnam, Jeff Falberg
--Last Updated: 9.25.2015

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity vgatest is
   port (
      clk, reset: in std_logic;
      sw: in std_logic_vector(2 downto 0);
      hsync, vsync: out  std_logic;
      rgb: out std_logic_vector(2 downto 0)
   );
end vgatest;

architecture arch of vgatest is

   signal rgb_reg, toDispConv: std_logic_vector(2 downto 0);
   signal video_on: std_logic;
   signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	
	signal divsig: STD_LOGIC;
	signal sig: unsigned (23 downto 0);
	signal mapindex, pixindex, toDisp: integer;
	--opaque (background)
	constant cblk0 : std_logic_vector(3 downto 0) := "0000";
	constant cblue0 : std_logic_vector(3 downto 0) := "0010";
	constant cgreen0 : std_logic_vector(3 downto 0) := "0100";
	constant ccyan0 : std_logic_vector(3 downto 0) := "0110";
	constant cred0 : std_logic_vector(3 downto 0) := "1000";
	constant cmag0 : std_logic_vector(3 downto 0) := "1010";
	constant cyel10 : std_logic_vector(3 downto 0) := "1100";
	constant cwht0 : std_logic_vector(3 downto 0) := "1110";
	--transparent (foreground)
	constant cblk1 : std_logic_vector(3 downto 0) := "0001";
	constant cblue1 : std_logic_vector(3 downto 0) := "0011";
	constant cgreen1 : std_logic_vector(3 downto 0) := "0101";
	constant ccyan1 : std_logic_vector(3 downto 0) := "0111";
	constant cred1 : std_logic_vector(3 downto 0) := "1001";
	constant cmag1 : std_logic_vector(3 downto 0) := "1011";
	constant cyel1 : std_logic_vector(3 downto 0) := "1101";
	constant cwht1: std_logic_vector(3 downto 0) := "1111";
	--signal pixdatB, pixdatF: std_logic_vector(3 downto 0);
	signal pixdatB, pixdatF: integer;
	--type sprite is array(0 to 63) of std_logic_vector(2 downto 0);
	type spArr is array(0 to 2047) of std_logic_vector(3 downto 0);
	type ground is array(0 to 1199) of integer; --location @ pixel XXXXX
	--type tile_map is array(0 to 31) of sprite;
	
	--define all sprites
	
	signal spriteArr : spArr := (
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--0
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cwht0, cwht0,
		cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
		cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
		cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
		cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
		cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0, cwht0,
		
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--1
		cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0,
		cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
		cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
		cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
		cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
		cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0,
		cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,
		
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--2
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--3
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--4
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--5
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--6
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--7
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		
		cwht0, cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0,	--8
		cwht0, cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, ccyan1,
		cwht0, cwht0, cwht0, cwht0, cblk1, cblk1, cblk1, cblk1,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cblk1, cblk1,
		cwht0, cwht0, cwht0, cwht0, cblk1, cblk1, cblk1, cblk1,
		cgreen1, cgreen1, cgreen1, cblk1, cblk1, cblue1, cblue1, cblue1,
		cgreen1, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,
		cgreen1, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,
		
		cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,	--9
		ccyan1, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,
		cblk1, cblk1, cblk1, cblk1, cwht0, cwht0, cwht0, cwht0,
		cblk1, cblk1, cwht0, cwht0, cwht0, cgreen1, cgreen1, cwht0,
		cblk1, cblk1, cblk1, cblk1, cwht0, cwht0, cgreen1, cwht0,
		cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cgreen1, cwht0,
		cblue1, cblue1, cblue1, cblue1, cblk1, cgreen1, cgreen1, cwht0,
		cblue1, cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--10
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--11
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--12
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--13
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--14
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--15
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--16
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--17
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--18
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--19
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--20
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--21
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--22
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--23
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--24
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		
		cgreen1, cgreen1, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,	--25
		cwht0, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,
		cwht0, cwht0, cwht0, cblk1, cblk1, cblue1, cblue1, cblue1,
		cwht0, cwht0, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1,
		cwht0, cwht0, cwht0, cblk1, cblk1, cblue1, cblue1, cblue1,
		cwht0, cwht0, cblk1, cblk1, cblue1, cblue1, cblue1, cblue1,
		cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cblk1,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		
		cblue1, cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0,	--26
		cblue1, cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0,
		cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cwht0, cwht0,
		cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0, cwht0,
		cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cwht0, cwht0,
		cblue1, cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cwht0,
		cblk1, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--27
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--28
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,	--29
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
		cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,

		cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,	--30
		cred0, cred0, cred0, cwht0, cwht0, cwht0, cwht0, cred0,
		cred0, cred0, cred0, cwht0, cred0, cred0, cwht0, cred0,
		cred0, cred0, cred0, cwht0, cred0, cred0, cwht0, cred0,
		cred0, cred0, cred0, cwht0, cwht0, cwht0, cwht0, cred0,
		cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,
		cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,
		cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,
		
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,	--31
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
		cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0);
	signal background : ground := (31, 31, 31, 31, 30, 31, 30, others => 31);
	signal foreground : ground := (
		0, 1, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
		8, 9, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
		25, 26, others => 29);
	
	--signal bkgnd : sprite := (cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag);
	--signal notsprite : sprite := (cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht, cwht);
	--signal rock : sprite := (cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cwht, cwht, cwht, cwht, cred, cred, cred, cred, cwht, cred, cred, cwht, cred, cred, cred, cred, cwht, cred, cred, cwht, cred, cred, cred, cred, cwht, cwht, cwht, cwht, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred);
	--top left of character
	
   component vgatimehelper
     port (
       clk, reset       : in std_logic;
       hsync, vsync     : out std_logic;
       video_on, p_tick : out std_logic;
       pixel_x, pixel_y : out std_logic_vector(9 downto 0));
   end component;

begin

  -- instantiate VGA sync circuit
   vga_unit: vgatimehelper
      port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               p_tick=>open, pixel_x=>pixel_x, pixel_y=>pixel_y);

	--get pixel location
	mapindex <= conv_integer(pixel_x(9 downto 4)) + (conv_integer(pixel_y(9 downto 4)) * 40);

	--determine which pixel to display
	--pixdatB <= spriteArr(background(mapindex) * 64);
	--pixdatF <= spriteArr(foreground(mapindex) * 64);
	pixdatF <= (((conv_integer(pixel_x) / 2) mod 8) + (64 * foreground(mapindex)) + ((conv_integer(pixel_y) / 2) mod 8) * 8);
	pixdatB <= (((conv_integer(pixel_x) / 2) mod 8) + (64 * background(mapindex)) + ((conv_integer(pixel_y) / 2) mod 8) * 8);
	--pixindex <= to_integer(shift_right(foreground(mapindex),1)) when pixdatF(0) = '1' else to_integer(background(mapindex) srl 1);

   -- rgb buffer (paint screen)
   process (clk,reset)
   begin
      if reset='1' then rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
			--which pixel is dominant?
			if (spriteArr(pixdatF)(0) = '1') then 
				--pixindex <= ((conv_integer(pixel_x) mod 8) + (64 * foreground(mapindex)) + (conv_integer(pixel_y) mod 8));--foreground(mapindex);
				rgb_reg <= spriteArr(pixdatF)(3 downto 1);
			else 
				--pixindex <= ((conv_integer(pixel_x) mod 8) + (64 * background(mapindex)) + (conv_integer(pixel_y) mod 8));--background(mapindex);
				rgb_reg <= spriteArr(pixdatB)(3 downto 1);
			end if;
			-- x mod 16 + y mod 16 + whatever we just got * 64
			--toDisp <= ((conv_integer(pixel_x) mod 8) + (64 * pixindex) + (conv_integer(pixel_y) mod 8) * 8);
			--toDispTemp <= to_StdLogicVector(toDisp);
			--toDispConv <= spriteArr(toDisp)(3 downto 1);
			--rgb_reg <= toDispConv;
			--rgb_reg <= spriteArr(pixindex)(3 downto 1);
		end if;
   end process;

   rgb <= rgb_reg when video_on='1' else "000";
end arch;
