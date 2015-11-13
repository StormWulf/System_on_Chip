-------------------------------------------------------------------------------
-- $Id: wr_buffer.vhd,v 1.2 2008/05/13 21:43:38 gburch Exp $
-------------------------------------------------------------------------------
-- wr_buffer - entity / architecture pair
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This text/file contains proprietary, confidential                    **
--  **  information of Xilinx, Inc., is distributed under                    **
--  **  license from Xilinx, Inc., and may be used, copied                   **
--  **  and/or disclosed only pursuant to the terms of a valid               **
--  **  license agreement with Xilinx, Inc. Xilinx hereby                    **
--  **  grants you a license to use this text/file solely for                **
--  **  design, simulation, implementation and creation of                   **
--  **  design files limited to Xilinx devices or technologies.              **
--  **  Use with non-Xilinx devices or technologies is expressly             **
--  **  prohibited and immediately terminates your license unless            **
--  **  covered by a separate agreement.                                     **
--  **                                                                       **
--  **  Xilinx is providing this design, code, or information                **
--  **  "as-is" solely for use in developing programs and                    **
--  **  solutions for Xilinx devices, with no obligation on the              **
--  **  part of Xilinx to provide support. By providing this design,         **
--  **  code, or information as one possible implementation of               **
--  **  this feature, application or standard, Xilinx is making no           **
--  **  representation that this implementation is free from any             **
--  **  claims of infringement. You are responsible for obtaining            **
--  **  any rights you may require for your implementation.                  **
--  **  Xilinx expressly disclaims any warranty whatsoever with              **
--  **  respect to the adequacy of the implementation, including             **
--  **  but not limited to any warranties or representations that this       **
--  **  implementation is free from claims of infringement, implied          **
--  **  warranties of merchantability or fitness for a particular            **
--  **  purpose.                                                             **
--  **                                                                       **
--  **  Xilinx products are not intended for use in life support             **
--  **  appliances, devices, or systems. Use in such applications is         **
--  **  expressly prohibited.                                                **
--  **                                                                       **
--  **  Any modifications that are made to the Source Code are               **
--  **  done at the user’s sole risk and will be unsupported.                **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Hotline support of original source         **
--  **  code IP shall only address issues and questions related              **
--  **  to the standard Netlist version of the core (and thus                **
--  **  indirectly, the original core source).                               **
--  **                                                                       **
--  **  Copyright (c) 2008 Xilinx, Inc. All rights reserved.                 **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
-------------------------------------------------------------------------------
-- Filename:        srl_fifo3.vhd
--
-- Description:     same as srl_fifo except the Addr port has the correct bit
--                  ordering, there is a true FIFO_Empty port, and the C_DEPTH
--                  generic actually controlls how many elements the fifo will
--                  hold (up to 16).  includes an assertion statement to check
--                  that C_DEPTH is less than or equal to 16.  changed
--                  C_DATA_BITS to C_DWIDTH and changed it from natural to
--                  positive (the width should be 1 or greater, zero width
--                  didn't make sense to me!).  Changed C_DEPTH from natural
--                  to positive (zero elements doesn't make sense).
--                  The Addr port in srl_fifo has the bits reversed which
--                  made it more difficult to use.  C_DEPTH was not used in
--                  srl_fifo.  Data_Exists is delayed by one clock so it is
--                  not usefull for generating an empty flag.  FIFO_Empty is
--                  generated directly from the address, the same way that
--                  FIFO_Full is generated.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              wr_buffer.vhd
--
-------------------------------------------------------------------------------
-- Author:          GAB
--
-- History:
--   GAB   10-10-05   First Version 
-- ~~~~~~
--
--  Modified srl_fifo3 from proc_common_v3_00_a
--  Added extra write port to reduce fanout for 128-bit case
--  Removed component declarations
--
-- ^^^^^^
--   GAB   10-26-06
-- ~~~~~~
--  Modified method for checking primitive support for vaiours devices and 
--  provided an inferred version for cases when the primitives are not
--  supported.
--
-- ^^^^^^
--      GAB    4/29/2008   v1.01.a     
-- ~~~~~~
--     - Updated to use proc_common_v3_00_a library
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.all;
use proc_common_v3_00_a.family_support.all;

library unisim;
use unisim.vcomponents.all;

entity wr_buffer is
  generic (
           C_FAMILY : string   := "virtex4";  -- latest and greatest
           C_DWIDTH : positive := 8;          -- changed to positive
           C_AWIDTH : positive := 4;          -- changed to positive
           C_DEPTH  : positive := 16          -- changed to positive
          );

  port    (
           Clk         : in  std_logic;
           Reset       : in  std_logic;
           FIFO_Write  : in  std_logic;
           FIFO_Write2 : in  std_logic;
           Data_In     : in  std_logic_vector(0 to C_DWIDTH-1);
           FIFO_Read   : in  std_logic;
           Data_Out    : out std_logic_vector(0 to C_DWIDTH-1);
           FIFO_Full   : out std_logic;
           FIFO_Empty  : out std_logic;
           Data_Exists : out std_logic;
           Addr        : out std_logic_vector(0 to C_AWIDTH-1)
          );

end entity wr_buffer;

architecture imp of wr_buffer is


constant USE_STRUCTURAL     : boolean := supported(C_FAMILY,(u_FDR,u_SRL16E,u_MUXCY_L,u_XORCY,u_FDRE,u_SRLC16E,u_LUT3,u_MUXF5,u_MUXF6));
constant USE_INFERRED       : boolean := not USE_STRUCTURAL;

------------------------------------------------------------------------------
-- Architecture BEGIN
------------------------------------------------------------------------------

begin

GEN_STRUCTURAL : if USE_STRUCTURAL generate
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    --                   GENERATE FOR C_DEPTH LESS THAN 17
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------

    C_DEPTH_LT_17 : if (C_DEPTH < 17) generate

        --------------------------------------------------------------------------
        -- Constant Declarations
        --------------------------------------------------------------------------

        -- convert C_DEPTH to a std_logic_vector so FIFO_Full can be generated
        -- based on the selected depth rather than fixed at 16
        constant DEPTH : std_logic_vector(0 to 3) :=
                                               std_logic_vector(to_unsigned(C_DEPTH-1,4));

        --------------------------------------------------------------------------
        -- Signal Declarations
        --------------------------------------------------------------------------

        signal addr_i       : std_logic_vector(0 to 3);  
        signal buffer_Full  : std_logic;
        signal buffer_Empty : std_logic;

        signal next_Data_Exists : std_logic;
        signal data_Exists_I    : std_logic;

        signal valid_Write : std_logic;

        signal hsum_A  : std_logic_vector(0 to 3);
        signal sum_A   : std_logic_vector(0 to 3);
        signal addr_cy : std_logic_vector(0 to 4);

        signal valid_Write2 : std_logic;
        --------------------------------------------------------------------------
        -- Component Declarations
        --------------------------------------------------------------------------


        --------------------------------------------------------------------------
        -- Begin for Generate
        --------------------------------------------------------------------------

        begin

        --------------------------------------------------------------------------
        -- Depth check and assertion
        --------------------------------------------------------------------------

        -- C_DEPTH is positive so that ensures the fifo is at least 1 element deep
        -- make sure it is not greater than 16 locations deep
        -- pragma translate_off
--coverage off
        assert C_DEPTH <= 16
        report "SRL Fifo's must be 16 or less elements deep"
        severity FAILURE;
--coverage on
        -- pragma translate_on

        --------------------------------------------------------------------------
        -- Concurrent Signal Assignments
        --------------------------------------------------------------------------

        -- since srl16 address is 3 downto 0 need to compare individual bits
        -- didn't muck with addr_i since the basic addressing works - Addr output
        -- is generated correctly below

        buffer_Full <= '1' when (addr_i(0) = DEPTH(3) and
                                 addr_i(1) = DEPTH(2) and
                                 addr_i(2) = DEPTH(1) and
                                 addr_i(3) = DEPTH(0)   ) else '0';

        FIFO_Full <= buffer_Full;

        buffer_Empty <= '1' when (addr_i = "0000") else '0';

        FIFO_Empty <= not data_Exists_I;   -- generate a true empty flag with no delay
                                           -- was buffer_Empty, which had a clock dly

        next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                            (buffer_Empty and FIFO_Write) or
                            (data_Exists_I and not FIFO_Read);

        Data_Exists <= data_Exists_I;

        valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

        valid_Write2 <= FIFO_Write2 and (FIFO_Read or not buffer_Full);

        addr_cy(0) <= valid_Write;

        --------------------------------------------------------------------------
        -- Data Exists DFF Instance
        --------------------------------------------------------------------------

        DATA_EXISTS_DFF : FDR
            port map (
                      Q  => data_Exists_I,     -- [out std_logic]
                      C  => Clk,               -- [in  std_logic]
                      D  => next_Data_Exists,  -- [in  std_logic]
                      R  => Reset              -- [in  std_logic]
                     );

        --------------------------------------------------------------------------
        -- GENERATE ADDRESS COUNTERS
        --------------------------------------------------------------------------

        Addr_Counters : for i in 0 to 3 generate

            hsum_A(i) <= (FIFO_Read xor addr_i(i)) and
                         (FIFO_Write or not buffer_Empty);

            MUXCY_L_I : MUXCY_L
                port map (
                          DI => addr_i(i),      -- [in  std_logic]
                          CI => addr_cy(i),     -- [in  std_logic]
                          S  => hsum_A(i),      -- [in  std_logic]
                          LO => addr_cy(i+1)    -- [out std_logic]
                         );

            XORCY_I : XORCY
                port map (
                          LI => hsum_A(i),      -- [in  std_logic]
                          CI => addr_cy(i),     -- [in  std_logic]
                          O  => sum_A(i)        -- [out std_logic]
                         );

            FDRE_I : FDRE
                port map (
                          Q  => addr_i(i),      -- [out std_logic]
                          C  => Clk,            -- [in  std_logic]
                          CE => data_Exists_i,  -- [in  std_logic]
                          D  => sum_A(i),       -- [in  std_logic]
                          R  => Reset           -- [in  std_logic]
                         );

        end generate Addr_Counters;

        --------------------------------------------------------------------------
        -- GENERATE FIFO RAM
        --------------------------------------------------------------------------

        FIFO_RAM : for I in 0 to (C_DWIDTH/2)-1 generate

            SRL16E_I : SRL16E
                -- pragma translate_off
                generic map ( INIT => x"0000" )
                -- pragma translate_on
                port map (
                          CE  => valid_Write,     -- [in  std_logic]
                          D   => Data_In(I),      -- [in  std_logic]
                          Clk => Clk,             -- [in  std_logic]
                          A0  => addr_i(0),       -- [in  std_logic]
                          A1  => addr_i(1),       -- [in  std_logic]
                          A2  => addr_i(2),       -- [in  std_logic]
                          A3  => addr_i(3),       -- [in  std_logic]
                          Q   => Data_Out(I)      -- [out std_logic]
                         );

        end generate FIFO_RAM;

        FIFO_RAM2  : for I in C_DWIDTH/2 to C_DWIDTH-1 generate

            SRL16E_I : SRL16E
                -- pragma translate_off
                generic map ( INIT => x"0000" )
                -- pragma translate_on
                port map (
                          CE  => valid_Write2,    -- [in  std_logic]
                          D   => Data_In(I),      -- [in  std_logic]
                          Clk => Clk,             -- [in  std_logic]
                          A0  => addr_i(0),       -- [in  std_logic]
                          A1  => addr_i(1),       -- [in  std_logic]
                          A2  => addr_i(2),       -- [in  std_logic]
                          A3  => addr_i(3),       -- [in  std_logic]
                          Q   => Data_Out(I)      -- [out std_logic]
                         );

        end generate FIFO_RAM2;



        --------------------------------------------------------------------------
        -- INT_ADDR_PROCESS
        --------------------------------------------------------------------------
        -- This process assigns the internal address to the output port
        --------------------------------------------------------------------------
           -- modified the process to flip the bits since the address bits from
           -- the srl16 are 3 downto 0 and Addr needs to be 0 to 3

          INT_ADDR_PROCESS:process (addr_i)
          begin
              for i in Addr'range
              loop
                  Addr(i) <= addr_i(3 - i); -- flip the bits to account
              end loop;                        --  for srl16 addr
          end process;

    end generate;


    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    --   GENERATE FOR C_DEPTH GREATER THAN 16, LESS THAN 32, 
    --   AND VIRTEX-2 AND NEWER FAMILIES
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------

    C_DEPTH_16_32_V2 : if ( (C_DEPTH > 16) and (C_DEPTH < 33)  )
    generate

        --------------------------------------------------------------------------
        -- Constant Declarations
        --------------------------------------------------------------------------

        constant DEPTH : std_logic_vector(0 to 4) :=
                                          std_logic_vector(to_unsigned(C_DEPTH-1,5));

        --------------------------------------------------------------------------
        -- Signal Declarations
        --------------------------------------------------------------------------

        signal addr_i       : std_logic_vector(0 to 4);  
        signal buffer_Full  : std_logic;
        signal buffer_Empty : std_logic;

        signal next_Data_Exists : std_logic;
        signal data_Exists_I    : std_logic;

        signal valid_Write : std_logic;

        signal hsum_A  : std_logic_vector(0 to 4);
        signal sum_A   : std_logic_vector(0 to 4);
        signal addr_cy : std_logic_vector(0 to 5);

        signal D_Out_ls : std_logic_vector(0 to C_DWIDTH-1); 
        signal D_Out_ms : std_logic_vector(0 to C_DWIDTH-1); 
        signal q15      : std_logic_vector(0 to C_DWIDTH-1);

        --------------------------------------------------------------------------
        -- Component Declarations
        --------------------------------------------------------------------------

        --------------------------------------------------------------------------
        -- Begin for Generate
        --------------------------------------------------------------------------

        begin

        --------------------------------------------------------------------------
        -- Concurrent Signal Assignments
        --------------------------------------------------------------------------

        --buffer_Full <= '1' when (addr_i = "11111") else '0';

        buffer_Full <= '1' when (addr_i(0) = DEPTH(4) and
                                 addr_i(1) = DEPTH(3) and
                                 addr_i(2) = DEPTH(2) and
                                 addr_i(3) = DEPTH(1) and
                                 addr_i(4) = DEPTH(0) ) else '0';

        FIFO_Full    <= buffer_Full;

        buffer_Empty <= '1' when (addr_i = "00000") else '0';

        FIFO_Empty   <= not data_Exists_I;   -- generate a true empty flag with no delay
                                             -- was buffer_Empty, which had a clock dly
        Data_Exists  <= data_Exists_I;
        addr_cy(0)   <= valid_Write;

        next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                            (buffer_Empty and FIFO_Write) or
                            (data_Exists_I and not FIFO_Read);

        --------------------------------------------------------------------------
        -- Data Exists DFF Instance
        --------------------------------------------------------------------------

        DATA_EXISTS_DFF : FDR
            port map (
                      Q  => data_Exists_i,     -- [out std_logic]
                      C  => Clk,               -- [in  std_logic]
                      D  => next_Data_Exists,  -- [in  std_logic]
                      R  => Reset              -- [in  std_logic]
                     );

        --------------------------------------------------------------------------
        -- Valid Write LUT Instance
        --------------------------------------------------------------------------

        -- XST CR183399 WA  
        --  valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

        VALID_WRITE_I : LUT3 
          generic map ( INIT => X"8A" )
          port map (
                    O  => valid_Write,
                    I0 => FIFO_Write,
                    I1 => FIFO_Read,
                    I2 => buffer_Full 
                   );
        --END XST WA for CR183399
        --------------------------------------------------------------------------
        -- GENERATE ADDRESS COUNTERS
        --------------------------------------------------------------------------

        ADDR_COUNTERS : for i in 0 to 4 generate

            hsum_A(I) <= (FIFO_Read xor addr_i(i)) and
                         (FIFO_Write or not buffer_Empty);

            MUXCY_L_I : MUXCY_L
                port map (
                          DI => addr_i(i),        -- [in  std_logic]
                          CI => addr_cy(i),       -- [in  std_logic]
                          S  => hsum_A(i),        -- [in  std_logic]
                          LO => addr_cy(i+1)      -- [out std_logic]
                         );

            XORCY_I : XORCY
                port map (
                          LI => hsum_A(i),        -- [in  std_logic]
                          CI => addr_cy(i),       -- [in  std_logic]
                          O  => sum_A(i)          -- [out std_logic]
                         );

            FDRE_I : FDRE
                port map (
                          Q  => addr_i(i),        -- [out std_logic]
                          C  => Clk,              -- [in  std_logic]
                          CE => data_Exists_i,    -- [in  std_logic]
                          D  => sum_A(i),         -- [in  std_logic]
                          R  => Reset             -- [in  std_logic]
                         );

        end generate Addr_Counters;

        --------------------------------------------------------------------------
        -- GENERATE FIFO RAMS
        --------------------------------------------------------------------------

        FIFO_RAM : for i in 0 to C_DWIDTH-1 generate
            SRLC16E_LS : SRLC16E
                -- pragma translate_off
                generic map ( INIT => x"0000" )
                -- pragma translate_on
                port map (
                          Q   => D_Out_ls(i),
                          Q15 => q15(i),
                          A0  => addr_i(0),
                          A1  => addr_i(1),
                          A2  => addr_i(2),
                          A3  => addr_i(3),
                          CE  => valid_Write,
                          CLK => Clk,
                          D   => Data_In(i)
                         );

          SRL16E_MS : SRL16E
            -- pragma translate_off
            generic map ( INIT => x"0000" )
            -- pragma translate_on
            port map (
                      CE  => valid_Write,  
                      D   => q15(i),  
                      Clk => Clk,  
                      A0  => addr_i(0),  
                      A1  => addr_i(1),  
                      A2  => addr_i(2),  
                      A3  => addr_i(3),  
                      Q   => D_Out_ms(i)
                     );

         MUXF5_I: MUXF5
             port map (
                       O  => Data_Out(i),  --[out]
                       I0 => D_Out_ls(i),  --[in]
                       I1 => D_Out_ms(i),  --[in]
                       S  => addr_i(4)     --[in]
                      );

        end generate FIFO_RAM;

        --------------------------------------------------------------------------
        -- INT_ADDR_PROCESS
        --------------------------------------------------------------------------
        -- This process assigns the internal address to the output port
        --------------------------------------------------------------------------

        INT_ADDR_PROCESS:process (addr_i)
        begin   -- process
            for i in Addr'range
            loop
                Addr(i) <= addr_i(4 - i); --flip the bits to account for srl16 addr
            end loop;
        end process;

    end generate;


    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    --   GENERATE FOR C_DEPTH GREATER THAN 32, LESS THAN 65, 
    --   AND VIRTEX-2 AND NEWER FAMILIES
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------

    C_DEPTH_32_64_V2 : if ( (C_DEPTH > 32) and (C_DEPTH < 65) ) --GAB 10/23/06
    generate

        --------------------------------------------------------------------------
        -- Constant Declarations
        --------------------------------------------------------------------------

        constant DEPTH : std_logic_vector(0 to 5) :=
                                            std_logic_vector(to_unsigned(C_DEPTH-1,6));

        --------------------------------------------------------------------------
        -- Signal Declarations
        --------------------------------------------------------------------------

        signal addr_i       : std_logic_vector(0 to 5);  
        signal buffer_Full  : std_logic;
        signal buffer_Empty : std_logic;

        signal next_Data_Exists : std_logic;
        signal data_Exists_I    : std_logic;

        signal valid_Write : std_logic;

        signal hsum_A  : std_logic_vector(0 to 5);
        signal sum_A   : std_logic_vector(0 to 5);
        signal addr_cy : std_logic_vector(0 to 6);

        signal D_Out_ls_1  : std_logic_vector(0 to C_DWIDTH-1); 
        signal D_Out_ls_2  : std_logic_vector(0 to C_DWIDTH-1); 
        signal D_Out_ls_3  : std_logic_vector(0 to C_DWIDTH-1); 
        signal D_Out_ms    : std_logic_vector(0 to C_DWIDTH-1); 
        signal Data_O_ls   : std_logic_vector(0 to C_DWIDTH-1); 
        signal Data_O_ms   : std_logic_vector(0 to C_DWIDTH-1); 
        signal q15_1       : std_logic_vector(0 to C_DWIDTH-1); 
        signal q15_2       : std_logic_vector(0 to C_DWIDTH-1); 
        signal q15_3       : std_logic_vector(0 to C_DWIDTH-1);

        --------------------------------------------------------------------------
        -- Component Declarations
        --------------------------------------------------------------------------


        --------------------------------------------------------------------------
        -- Begin for Generate
        --------------------------------------------------------------------------

        begin

        --------------------------------------------------------------------------
        -- Concurrent Signal Assignments
        --------------------------------------------------------------------------

        --  buffer_Full <= '1' when (addr_i = "11111") else '0';
        buffer_Full <= '1' when (addr_i(0) = DEPTH(5) and
                                 addr_i(1) = DEPTH(4) and
                                 addr_i(2) = DEPTH(3) and
                                 addr_i(3) = DEPTH(2) and
                                 addr_i(4) = DEPTH(1) and
                                 addr_i(5) = DEPTH(0)
                                ) else '0';

        FIFO_Full   <= buffer_Full;

        buffer_Empty <= '1' when (addr_i = "000000") else '0';

        FIFO_Empty <= not data_Exists_I;   -- generate a true empty flag with no delay
                                           -- was buffer_Empty, which had a clock dly

        next_Data_Exists <= (data_Exists_I and not buffer_Empty) or
                            (buffer_Empty and FIFO_Write) or
                            (data_Exists_I and not FIFO_Read);

        Data_Exists <= data_Exists_I;
        addr_cy(0)  <= valid_Write;

        --------------------------------------------------------------------------
        -- Data Exists DFF Instance
        --------------------------------------------------------------------------

        Data_Exists_DFF : FDR
            port map (
                      Q  => data_Exists_I,       -- [out std_logic]
                      C  => Clk,                 -- [in  std_logic]
                      D  => next_Data_Exists,    -- [in  std_logic]
                      R  => Reset                -- [in  std_logic]
                     );

        --------------------------------------------------------------------------
        -- Valid Write LUT Instance
        --------------------------------------------------------------------------

        -- XST CR183399 WA  
        --  valid_Write <= FIFO_Write and (FIFO_Read or not buffer_Full);

        VALID_WRITE_I : LUT3 
          generic map ( INIT => X"8A" )
          port map (
                    O  => valid_Write,           -- [out std_logic]
                    I0 => FIFO_Write,            -- [in  std_logic]
                    I1 => FIFO_Read,             -- [in  std_logic]
                    I2 => buffer_Full            -- [in  std_logic]
                   );
        --END XST WA for CR183399

        --------------------------------------------------------------------------
        -- GENERATE ADDRESS COUNTERS
        --------------------------------------------------------------------------

        ADDR_COUNTERS : for i in 0 to 5 generate

            hsum_A(I) <= (FIFO_Read xor addr_i(I)) and
                         (FIFO_Write or not buffer_Empty);

            MUXCY_L_I : MUXCY_L
                port map (
                          DI => addr_i(i),           -- [in  std_logic]
                          CI => addr_cy(i),          -- [in  std_logic]
                          S  => hsum_A(i),           -- [in  std_logic]
                          LO => addr_cy(i+1)         -- [out std_logic]
                         );

            XORCY_I : XORCY
                port map (
                          LI => hsum_A(i),           -- [in  std_logic]
                          CI => addr_cy(i),          -- [in  std_logic]
                          O  => sum_A(i)             -- [out std_logic]
                         );

            FDRE_I : FDRE
                port map (
                          Q  => addr_i(i),           -- [out std_logic]
                          C  => Clk,                 -- [in  std_logic]
                          CE => data_Exists_i,       -- [in  std_logic]
                          D  => sum_A(i),            -- [in  std_logic]
                          R  => Reset                -- [in  std_logic]
                         );

        end generate ADDR_COUNTERS;

        --------------------------------------------------------------------------
        -- GENERATE FIFO RAMS
        --------------------------------------------------------------------------

        FIFO_RAM : for i in 0 to C_DWIDTH-1 generate

            SRLC16E_LS1 : SRLC16E
                -- pragma translate_off
                generic map ( INIT => x"0000" )
                -- pragma translate_on
                port map (
                          Q   => D_Out_ls_1(i),  --[out]
                          Q15 => q15_1(i),       --[out]
                          A0  => addr_i(0),      --[in]
                          A1  => addr_i(1),      --[in]
                          A2  => addr_i(2),      --[in]
                          A3  => addr_i(3),      --[in]
                          CE  => valid_Write,    --[in]
                          CLK => Clk,        --[in]
                          D   => Data_In(i)      --[in]
                         );

            SRLC16E_LS2 : SRLC16E
                -- pragma translate_off
                generic map ( INIT => x"0000" )
                -- pragma translate_on
                port map (
                          Q   => D_Out_ls_2(i),  --[out]
                          Q15 => q15_2(i),       --[out]
                          A0  => addr_i(0),      --[in]
                          A1  => addr_i(1),      --[in]
                          A2  => addr_i(2),      --[in]
                          A3  => addr_i(3),      --[in]
                          CE  => valid_Write,    --[in]
                          CLK => Clk,        --[in]
                          D   => q15_1(i)        --[in]
                         );

            MUXF5_LS: MUXF5
                port map (
                  O  => Data_O_LS(i),            --[out]
                  I0 => D_Out_ls_1(I),           --[in]
                  I1 => D_Out_ls_2(I),           --[in]
                  S  => addr_i(4)                --[in]
                 );


            SRLC16E_LS3 : SRLC16E
                -- pragma translate_off
                generic map ( INIT => x"0000" )
                -- pragma translate_on
                port map (
                          Q   => D_Out_ls_3(i),  --[out]
                          Q15 => q15_3(i),       --[out]
                          A0  => addr_i(0),      --[in]
                          A1  => addr_i(1),      --[in]
                          A2  => addr_i(2),      --[in]
                          A3  => addr_i(3),      --[in]
                          CE  => valid_Write,    --[in]
                          CLK => Clk,            --[in]
                          D   => q15_2(i)        --[in]
                         );

            SRL16E_MS : SRL16E
                -- pragma translate_off
                generic map ( INIT => x"0000" )
                -- pragma translate_on
                port map (
                          CE  => valid_Write,    --[in]
                          D   => q15_3(i),       --[in]
                          Clk => Clk,            --[in]
                          A0  => addr_i(0),      --[in]
                          A1  => addr_i(1),      --[in]
                          A2  => addr_i(2),      --[in]
                          A3  => addr_i(3),      --[in]
                          Q   => D_Out_ms(I)     --[out]
                         );

            MUXF5_MS: MUXF5
                port map (
                          O  => Data_O_MS(i),    --[out]
                          I0 => D_Out_ls_3(i),   --[in]
                          I1 => D_Out_ms(i),     --[in]
                          S  => addr_i(4)        --[in]
                         );

            MUXF6_I: MUXF6
                port map (
                          O  => Data_out(i),     --[out]
                          I0 => Data_O_ls(i),    --[in]
                          I1 => Data_O_ms(i),    --[in]
                          S  => addr_i(5)        --[in]
                         );

        end generate FIFO_RAM;

        --------------------------------------------------------------------------
        -- INT_ADDR_PROCESS
        --------------------------------------------------------------------------
        -- This process assigns the internal address to the output port
        --------------------------------------------------------------------------
        INT_ADDR_PROCESS:process (addr_i)
        begin
            for i in Addr'range
            loop
                Addr(i) <= addr_i(5 - i);  -- flip the bits to account for srl16 addr
            end loop;
        end process;

    end generate;
end generate GEN_STRUCTURAL;

--coverage off
GEN_INFERRED : if USE_INFERRED generate

    --------------------------------------------------------------------------
    -- Constant Declarations
    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- Signal Declarations
    --------------------------------------------------------------------------

    signal addr_i_1           : std_logic_vector(0 to C_AWIDTH-1);  
    signal buffer_Full_1      : std_logic;
    signal next_buffer_Full_1 : std_logic;
    signal next_Data_Exists_1 : std_logic;
    signal data_Exists_I_1    : std_logic;


    type dataType is array (0 to C_DEPTH-1) of std_logic_vector(0 to C_DWIDTH-1);
    signal data: dataType;

    --------------------------------------------------------------------------
    -- Component Declarations
    --------------------------------------------------------------------------
    constant ALL_ONES       : std_logic_vector(0 to C_AWIDTH-1) := (others => '1');
    constant ALL_ZEROS      : std_logic_vector(0 to C_AWIDTH-1) := (others => '0');
    --------------------------------------------------------------------------
    -- Begin for Generate
    --------------------------------------------------------------------------
  
    begin

    --------------------------------------------------------------------------
    -- Concurrent Signal Assignments
    --------------------------------------------------------------------------


    data_Exists  <= data_Exists_I_1;
    FIFO_Full    <= buffer_Full_1;

    FIFO_Empty  <= not data_Exists_I_1;
    Addr        <= addr_i_1;


    --------------------------------------------------------------------------
    -- Address Processes
    --------------------------------------------------------------------------

    ADDRS_1 : process (Clk)
    begin
        if (clk'event and clk = '1') then
            if (Reset = '1') then
                addr_i_1 <= (others => '0');
            elsif ((buffer_Full_1='0') and (FIFO_Write='1') and
                   (FIFO_Read='0') and (data_Exists_I_1='1')) then
                addr_i_1 <= std_logic_vector(unsigned(addr_i_1) + 1);


            elsif (not(addr_i_1 = ALL_ZEROS) and (FIFO_Read='1') and 
                  (FIFO_Write='0')) then
                addr_i_1 <= std_logic_vector(unsigned(addr_i_1) - 1);
            end if;
        end if;
    end process;


    --------------------------------------------------------------------------
    -- Data Exists Instances
    --------------------------------------------------------------------------
   
          

    next_Data_Exists_1 <= ((FIFO_Write and not(FIFO_Read) and not(or_reduce(addr_i_1))) or data_Exists_I_1)
                   and not (FIFO_Read and not(FIFO_Write) and not(or_reduce(addr_i_1)));
    
    

    REG_DATA_EXIST : process(Clk)
        begin
            if(Clk'EVENT and Clk='1')then
                if(Reset='1')then
                    data_Exists_I_1 <= '0';
                else
                    data_Exists_I_1 <= next_Data_Exists_1;
                end if;
            end if;
        end process REG_DATA_EXIST;
        

    --------------------------------------------------------------------------
    -- Buffer Full Instances
    --------------------------------------------------------------------------
    next_buffer_Full_1  <= '1' when (addr_i_1 = ALL_ONES) else '0';

    REG_BUFFER_FULL : process(Clk)
        begin
            if(Clk'EVENT and Clk='1')then
                if(Reset='1')then
                    buffer_Full_1 <= '0';
                else
                    buffer_Full_1 <= next_buffer_Full_1;
                end if;
            end if;
        end process REG_BUFFER_FULL;
  
    ----------------------------------------------------------------------------
    -- Inferred FIFO element.
    ----------------------------------------------------------------------------
    INFRD_FIFO1 : process(Clk)
    begin
      if Clk'event and Clk = '1' then
        if FIFO_Write = '1' then
          data <= Data_In & data(0 to C_DEPTH-2);
        end if;
      end if;
    end process;

    Data_Out <= data(TO_INTEGER(UNSIGNED(addr_i_1)))
                when (TO_INTEGER(UNSIGNED(addr_i_1)) < C_DEPTH)
                else
            (others => '0');


end generate GEN_INFERRED;
--coverage on


end architecture imp;
