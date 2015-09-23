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
	constant cblue : std_logic_vector(2 downto 0) := "001";
	constant cgreen : std_logic_vector(2 downto 0) := "010";
	constant cred: std_logic_vector(2 downto 0) := "100";
	constant ctrans: std_logic_vector(2 downto 0) := "111";
	type tile_map is array(0 to 1199) of std_logic_vector(2 downto 0);
	signal grid_map : tile_map := (
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans,
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans,
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans, 
		cblue, cgreen, cred, ctrans, cblue, cgreen, cred, ctrans);
	
	signal mapindex : integer;

   component vgatimehelper
     port (
       clk, reset       : in std_logic;
       hsync, vsync     : out std_logic;
       video_on, p_tick : out std_logic;
       pixel_x, pixel_y : out std_logic_vector(9 downto 0));
   end component;

begin

	--clock divider
--	process(clk, divsig, sig)
--		begin
--		if (clk'event and clk = '1') then
--			sig <= sig + 1;
--		end if;
--		divsig <= sig(5);
--	end process;

  -- instantiate VGA sync circuit
   vga_unit: vgatimehelper
      port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               p_tick=>open, pixel_x=>pixel_x, pixel_y=>pixel_y);

	mapindex <= conv_integer(pixel_x(9 downto 4)) + (conv_integer(pixel_y(9 downto 4)) * 40);

   -- rgb buffer
   process (clk,reset)
   begin
      if reset='1' then
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         rgb_reg <= grid_map(mapindex);--sw;
      end if;
   end process;
	
	--paint the screen
--	process(reset, divsig)
--	begin
--			if (reset = '1') then rgb <= "000";
--			elsif (divsig'event and divsig = '1') then
--				mapindex <= std_logic_vector((signed((pixel_x)) + signed((pixel_y)) * 40));
--				rgb <= grid_map(conv_integer(mapindex));
--			end if;
--	end process;

   rgb <= rgb_reg when video_on='1' else "000";
end arch;
