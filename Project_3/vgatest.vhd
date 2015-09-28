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
	signal mapindex : integer;
	constant cblk : std_logic_vector(2 downto 0) := "000";
	constant cblue : std_logic_vector(2 downto 0) := "001";
	constant cgreen : std_logic_vector(2 downto 0) := "010";
	constant ccyan : std_logic_vector(2 downto 0) := "011";
	constant cred: std_logic_vector(2 downto 0) := "100";
	constant cmag: std_logic_vector(2 downto 0) := "101";
	constant cyel: std_logic_vector(2 downto 0) := "110";
	constant ctrans: std_logic_vector(2 downto 0) := "111";
	type sprite is array(0 to 63) of std_logic_vector(2 downto 0);
	type tile_map is array(0 to 31) of sprite;
	
	--define all sprites
	signal bkgnd : sprite := (cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag, cmag);
	signal notsprite : sprite := (ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans);
	signal rock : sprite := (cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, ctrans, ctrans, ctrans, ctrans, cred, cred, cred, cred, ctrans, cred, cred, ctrans, cred, cred, cred, cred, ctrans, cred, cred, ctrans, cred, cred, cred, cred, ctrans, ctrans, ctrans, ctrans, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred, cred);
	--top left of character
	signal char1 : sprite := (
		ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans,
		ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans,
		ctrans, ctrans, cblk, cblk, cblk, cblk, ctrans, ctrans,
		ctrans, cblk, cyel, cyel, cred, cred, cblk, ctrans,
		ctrans, cblk, cyel, cyel, cred, cred, cblk, ctrans,
		ctrans, cblk, cyel, cyel, cred, cred, cblk, ctrans,
		ctrans, cblk, cyel, cyel, cred, cred, cblk, ctrans,
		ctrans, cblk, cblk, cblk, cblk, cblk, ctrans, ctrans);
	--top right of character
	signal char2 : sprite := (
		ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans,
		ctrans, ctrans, cblk, cblk, cblk, cblk, cblk, ctrans,
		ctrans, cblk, cred, cred, cred, cyel, cyel, cblk,
		ctrans, cblk, cred, cred, cred, cyel, cyel, cblk,
		ctrans, cblk, cred, cred, cred, cyel, cyel, cblk,
		ctrans, cblk, cred, cred, cred, cyel, cyel, cblk,
		ctrans, ctrans, cblk, cblk, cblk, cblk, cblk, ctrans,
		ctrans, ctrans, ctrans, cblk, ctrans, ctrans, ctrans, ctrans);
	--mid left of character
	signal char3 : sprite := (
		ctrans, ctrans, ctrans, ctrans, cblk, ctrans, ctrans, ctrans,
		ctrans, ctrans, ctrans, ctrans, cblk, ctrans, ctrans, ccyan,
		ctrans, ctrans, ctrans, ctrans, cblk, cblk, cblk, cblk,
		ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, cblk, cblk,
		ctrans, ctrans, ctrans, ctrans, cblk, cblk, cblk, cblk,
		cgreen, cgreen, cgreen, cblk, cblk, cblue, cblue, cblue,
		cgreen, ctrans, ctrans, cblk, cblue, cblue, cblue, cblue,
		cgreen, ctrans, ctrans, cblk, cblue, cblue, cblue, cblue);
	--mid right of character
	signal char4 : sprite := (
		ctrans, ctrans, ctrans, cblk, ctrans, ctrans, ctrans, ctrans,
		ccyan, ctrans, ctrans, cblk, ctrans, ctrans, ctrans, ctrans,
		cblk, cblk, cblk, cblk, ctrans, ctrans, ctrans, ctrans,
		cblk, cblk, ctrans, ctrans, ctrans, cgreen, cgreen, ctrans,
		cblk, cblk, cblk, cblk, ctrans, ctrans, cgreen, ctrans,
		cblue, cblue, cblue, cblk, cblk, ctrans, cgreen, ctrans,
		cblue, cblue, cblue, cblue, cblk, cgreen, cgreen, ctrans,
		cblue, cblue, cblue, cblue, cblk, ctrans, ctrans, ctrans);
	--bottom left of character
	signal char5 : sprite := (
		cgreen, cgreen, ctrans, cblk, cblue, cblue, cblue, cblue,
		ctrans, ctrans, ctrans, cblk, cblue, cblue, cblue, cblue,
		ctrans, ctrans, ctrans, cblk, cblk, cblue, cblue, cblue,
		ctrans, ctrans, ctrans, ctrans, cblk, cblue, cblue, cblue,
		ctrans, ctrans, ctrans, cblk, cblk, cblue, cblue, cblue,
		ctrans, ctrans, cblk, cblk, cblue, cblue, cblue, cblue,
		ctrans, ctrans, cblk, cblk, cblk, cblk, cblk, cblk,
		ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans);
	--bottom right of character
	signal char6 : sprite := (
		cblue, cblue, cblue, cblue, cblk, ctrans, ctrans, ctrans,
		cblue, cblue, cblue, cblue, cblk, ctrans, ctrans, ctrans,
		cblue, cblue, cblue, cblk, cblk, ctrans, ctrans, ctrans,
		cblue, cblue, cblue, cblk, ctrans, ctrans, ctrans, ctrans,
		cblue, cblue, cblue, cblk, cblk, ctrans, ctrans, ctrans,
		cblue, cblue, cblue, cblue, cblk, cblk, ctrans, ctrans,
		cblk, cblk, cblk, cblk, cblk, cblk, ctrans, ctrans,
		ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans, ctrans);
	--foreground (w/ sprite)
	signal foreground : tile_map := (
		notsprite, notsprite, notsprite, notsprite, notsprite, notsprite, notsprite, notsprite, 
		notsprite, notsprite, notsprite, notsprite, char1, char2, notsprite, notsprite, 
		notsprite, notsprite, notsprite, notsprite, char3, char4, notsprite, notsprite, 
		notsprite, notsprite, notsprite, notsprite, char5, char6, notsprite, notsprite);
	--background (rocks mixed in)
	signal background : tile_map := (
		bkgnd, bkgnd, bkgnd, bkgnd, bkgnd, bkgnd, bkgnd, bkgnd,
		bkgnd, bkgnd, bkgnd, rock, bkgnd, bkgnd, bkgnd, bkgnd,
		bkgnd, bkgnd, bkgnd, bkgnd, bkgnd, rock, bkgnd, bkgnd,
		bkgnd, bkgnd, bkgnd, rock, bkgnd, bkgnd, bkgnd, bkgnd);


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

	--translate sprite pixel to rgb_reg???

   -- rgb buffer (paint screen)
   process (clk,reset)
   begin
      if reset='1' then
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
			--if statement for fore/back
			--if () then
			--elsif () then
         rgb_reg <= background(mapindex);
      end if;
   end process;

   rgb <= rgb_reg when video_on='1' else "000";
end arch;
