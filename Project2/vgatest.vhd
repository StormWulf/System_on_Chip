--file: vgatest.vhd
--Authors: William Putnam, Jeff Falberg
--Last Updated: 9.25.2015

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vgatest is
   port (
      clk, reset: in std_logic;
      sw: in std_logic_vector(2 downto 0);
      hsync, vsync: out  std_logic;
      rgb: out std_logic_vector(2 downto 0)
   );
end vgatest;

architecture arch of vgatest is

   signal rgb_reg: std_logic_vector(2 downto 0);
   signal video_on: std_logic;
   signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	
	signal divsig: STD_LOGIC;
	signal sig: unsigned (23 downto 0);
	constant cblk : std_logic_vector(2 downto 0) := "000";
	constant cblue : std_logic_vector(2 downto 0) := "001";
	constant cgreen : std_logic_vector(2 downto 0) := "010";
	constant ccyan : std_logic_vector(2 downto 0) := "011";
	constant cred: std_logic_vector(2 downto 0) := "100";
	constant cmag: std_logic_vector(2 downto 0) := "101";
	constant cyel: std_logic_vector(2 downto 0) := "110";
	constant ctrans: std_logic_vector(2 downto 0) := "111";
	type tile_map is array(0 to 1199) of std_logic_vector(2 downto 0);
	signal grid_map : tile_map := (
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans,
		cblk, cblue, cgreen, ccyan, cred, cmag, cyel, ctrans);
	
	signal mapindex : integer;

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

   -- rgb buffer (paint screen)
   process (clk,reset)
   begin
      if reset='1' then
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         rgb_reg <= grid_map(mapindex);
      end if;
   end process;

   rgb <= rgb_reg when video_on='1' else "000";
end arch;
