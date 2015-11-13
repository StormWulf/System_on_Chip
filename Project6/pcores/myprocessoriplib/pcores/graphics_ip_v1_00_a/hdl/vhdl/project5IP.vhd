--file: project5IP.vhd
--Authors: William Putnam, Jeff Falberg
--Last Updated: 10.31.2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project5IP is
	port (
		clk, reset : in std_logic;
		hsync, vsync : out std_logic;
		rgb: out std_logic_vector(2 downto 0);
		dataPort : in std_logic_vector(31 downto 0)
	);
end project5IP;

architecture Behavioral of project5IP is
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
	signal pixdatB, pixdatF: integer;

	type ramtype is array(0 to 2047) of std_logic_vector(3 downto 0);
	type ground is array(0 to 1199) of std_logic_vector(5 downto 0); --location @ pixel XXXXX
	signal ramF, ramB : ground;
	signal ramS : ramtype;
	
	signal wEnF, wEnB, wEnS : std_logic;
	signal dataInF, dataInB : std_logic_vector(5 downto 0);
	signal dataInS : std_logic_vector(3 downto 0);
	signal addr : std_logic_vector(11 downto 0);

	component vgatimehelper
     port (
       clk, reset       : in std_logic;
       hsync, vsync     : out std_logic;
       video_on, p_tick : out std_logic;
       pixel_x, pixel_y : out std_logic_vector(9 downto 0));
   end component;

	begin

	wEnF <= dataPort(31);
	wEnB <= dataPort(30);
	wEnS <= dataPort(29);
	dataInS <= dataPort(27 downto 24);
	dataInF <= dataPort(23 downto 18);
	dataInB <= dataPort(17 downto 12);
	addr <= dataPort(11 downto 0);

	--foreground process
		process(clk)
		begin
			if (rising_edge(clk)) then
				if (wEnF = '1') then ramF(conv_integer(addr)) <= dataInF;
				end if;
			end if;
		end process;
	--background process
		process(clk)
		begin
			if (rising_edge(clk)) then
				if (wEnB = '1') then ramB(conv_integer(addr)) <= dataInB;
				end if;
			end if;
		end process;
	--sprite map process
		process(clk)
		begin
			if (rising_edge(clk)) then
				if (wEnS = '1') then ramS(conv_integer(addr)) <= dataInS;
				end if;
			end if;
		end process;

  -- instantiate VGA sync circuit
    vga_unit: vgatimehelper
	--vga_unit: entity work.vgatimehelper
      port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               p_tick=>open, pixel_x=>pixel_x, pixel_y=>pixel_y);

	--get pixel location
	mapindex <= conv_integer(pixel_x(9 downto 4)) + (conv_integer(pixel_y(9 downto 4)) * 40);

	--determine which pixel to display
	pixdatF <= (((conv_integer(pixel_x) / 2) mod 8) + (64 * conv_integer(ramF(mapindex))) + ((conv_integer(pixel_y) / 2) mod 8) * 8);
	pixdatB <= (((conv_integer(pixel_x) / 2) mod 8) + (64 * conv_integer(ramB(mapindex))) + ((conv_integer(pixel_y) / 2) mod 8) * 8);

   -- rgb buffer (paint screen)
   process (clk,reset)
   begin
      if reset='1' then rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
			--which pixel is dominant?
			if (ramS(pixdatF)(0) = '1') then rgb_reg <= ramS(pixdatF)(3 downto 1);
			else rgb_reg <= ramS(pixdatB)(3 downto 1);
			end if;
		end if;
   end process;

   rgb <= rgb_reg when video_on='1' else "000";

end Behavioral;

