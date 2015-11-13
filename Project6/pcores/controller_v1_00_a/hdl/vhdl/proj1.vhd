--file: proj1.vhd
--Authors: William Putnam, Jeff Falberg
--Last Updated: 11.6.2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level_test is
    Port ( reset, clk, NESdatIn : in std_logic;
		NESdata : out std_logic_vector(7 downto 0);
		NESlatch, NESclk : out std_logic
		);
end top_level_test;

--read data from the controller
architecture Behavioral of top_level_test is
	signal divsig: STD_LOGIC;
	signal sig: unsigned (23 downto 0);
	signal shift: STD_LOGIC_VECTOR (7 downto 0);
	type states is (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16);
	signal stateNow, stateNext : states;
	begin

	--clock divider
	process(clk, divsig, sig)
		begin
		if (clk'event and clk = '1') then
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
	process(stateNow, stateNext, NESdatIn)
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
				shift(0) <= NESdatIn;
				NESclk <= '0';
				stateNext <= s3;
			when s3 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s4;
			when s4 =>
				shift(1) <= NESdatIn;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s5;
			when s5 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s6;
			when s6 =>
				shift(2) <= NESdatIn;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s7;
			when s7 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s8;
			when s8 =>
				shift(3) <= NESdatIn;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s9;
			when s9 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s10;
			when s10 =>
				shift(4) <= NESdatIn;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s11;
			when s11 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s12;
			when s12 =>
				shift(5) <= NESdatIn;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s13;
			when s13 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <=s14;
			when s14 =>
				shift(6) <= NESdatIn;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s15;
			when s15 =>
				NESlatch <= '0';
				NESclk <= '1';
				stateNext <= s16;
			when s16 =>
				shift(7) <= NESdatIn;
				NESlatch <= '0';
				NESclk <= '0';
				stateNext <= s0;
			when others => stateNext <= s0;
		end case;
	end process;
	NESdata <= shift;
	
end Behavioral;

