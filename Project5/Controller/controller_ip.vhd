----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:07:40 11/04/2015 
-- Design Name: 
-- Module Name:    controller_ip - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_ip is
	Port ( reset : in  STD_LOGIC;
           clk_50mhz : in  STD_LOGIC;
           buttonLED : out  STD_LOGIC_VECTOR (7 downto 0);
           NESlatch : out  STD_LOGIC;
           NESclk : out  STD_LOGIC;
           NESdatIN : in  STD_LOGIC);
end controller_ip;

--read data from the controller
architecture Behavioral of controller_ip is
	signal divsig: STD_LOGIC;
	signal sig: unsigned (23 downto 0);
	signal shift: STD_LOGIC_VECTOR (7 downto 0);
	type states is (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16);
	signal stateNow, stateNext : states;
	begin
	
	--clock divider
	process(clk_50mhz, divsig, sig)
		begin
		if (clk_50mhz'event and clk_50mhz = '1') then
			sig <= sig + 1;
		end if;
		divsig <= sig(5);
	end process;
	
	--clock activity defined here
	--states are cycled through
	process(reset, divsig)
		begin
			if (reset = '1') then stateNow <= s0;
			elsif(rising_edge(divsig)) then stateNow <= stateNext;
			end if;
	end process;

	--state machine for new clock
	--s0, s1 are latch related
	--preceding even states read data (NESclk is high)
	--preceding odd states do not (NESclk is low)
	process(stateNow, stateNext, NESdatIN)
		begin
		case stateNow is
			when s0 =>
				NESlatch <= '1';
				NESclk <= '0';
				stateNext <= s1;
			when s1 =>
				NESlatch <= '1';
				NESclk <= '0';
				stateNext <= s2;
			when s2 =>
				NESlatch <= '0';
				shift(0) <= NESdatIN;
				NESclk <= '0';
				stateNext <= s3;
			when s3 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s4;
			when s4 =>
				shift(1) <= NESdatIN;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s5;
			when s5 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s6;
			when s6 =>
				shift(2) <= NESdatIN;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s7;
			when s7 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s8;
			when s8 =>
				shift(3) <= NESdatIN;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s9;
			when s9 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s10;
			when s10 =>
				shift(4) <= NESdatIN;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s11;
			when s11 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s12;
			when s12 =>
				shift(5) <= NESdatIN;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s13;
			when s13 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <=s14;
			when s14 =>
				shift(6) <= NESdatIN;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s15;
			when s15 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s16;
			when s16 =>
				shift(7) <= NESdatIN;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s0;
			when others => stateNext <= s0;
		end case;
	end process;
	buttonLED <= not shift;
	
end Behavioral;

