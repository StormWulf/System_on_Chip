-------------------------------------------------------------------------------
-- counters.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
-- ***************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2007, 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
-- ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        counters.vhd
-- Description:     This file contains the counters for timing read/write 
--                  timing parameters. 
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  emc.vhd
--                      -- ipic_if.vhd
--                      -- addr_counter_mux.vhd
--                      -- counters.vhd
--                      -- select_param.vhd
--                      -- mem_state_machine.vhd
--                      -- mem_steer.vhd
--                      -- io_registers.vhd
-------------------------------------------------------------------------------
-- Author:          NSK
-- History:
-- NSK             02/01/08    First Version
-- ^^^^^^^^^^
-- This file is same as in version v2_01_c - no change in the logic of this 
-- module. Deleted the history from version v2_01_c.
-- ~~~~~~
-- NSK         05/08/08    version v3_00_a
-- ^^^^^^^^
-- 1. This file is same as in version v2_02_a.
-- 2. Upgraded to version v3.00.a to have proper versioning to fix CR #472164.
-- 3. No change in design.
-- ~~~~~~~~
-- ^^^^^^^^
-- KSB         08/08/08    version v4_00_a
-- 1. Added TPACC counter
-- ~~~~~~~~
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- Proc common package of the proc common library is used for ld_arith_reg
-- declarations
-------------------------------------------------------------------------------

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ld_arith_reg;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
-- Definition of Ports:
-- Inputs
--      Synch_mem               -- Synchronous Memory Flag 
--      Twr_data                -- Write cycle counter data
--      Twr_load                -- Write cycle counter load
--      Twr_cnt_en              -- Write cycle count enable
--      Tlz_data                -- Write End to Low-Z counter data
--      Tlz_load                -- Write End to Low-Z counter load
--      Trd_data                -- Read cycle counter data
--      Trd_load                -- Read cycle counter load
--      Trd_cnt_en              -- Read cycle count enable
--      Thz_data                -- Read End to High-Z counter data
--      Thz_load                -- Read End to High-Z counter load
--
-- Outputs
--      Twr_end                 -- Write cycle count complete     
--      Tlz_end                 -- Write Recover count complete     
--      Trd_end                 -- Read cycle count complete     
--      Thz_end                 -- Read Recover count complete     
--
-- Clock and reset
--      Clk                     -- System Clock
--      Rst                     -- System Reset
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity counters is
    port (
        Synch_mem               : in  std_logic;

        Twr_data                : in  std_logic_vector(0 to 4);
        Twr_load                : in  std_logic;
        Twr_cnt_en              : in  std_logic;
        
        Tlz_data                : in  std_logic_vector(0 to 4);
        Tlz_load                : in  std_logic;

        Trd_data                : in  std_logic_vector(0 to 4);
        Trd_load                : in  std_logic;
        Trd_cnt_en              : in  std_logic;

        Thz_data                : in  std_logic_vector(0 to 4);
        Thz_load                : in  std_logic;
        
        
        Tpacc_data   		: in  std_logic_vector(0 to 4);
        Tpacc_load   		: in  std_logic;
        Tpacc_cnt_en 		: in  std_logic;
        

        Twr_end                 : out std_logic;
        Tlz_end                 : out std_logic;
        Trd_end                 : out std_logic;
        Thz_end                 : out std_logic;

	Tpacc_end		: out std_logic;

        Clk                     : in  std_logic;
        Rst                     : in  std_logic
    );
end entity counters;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture imp of counters is
-------------------------------------------------------------------------------
-- Constant declarations
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Assigning zero values
-------------------------------------------------------------------------------
constant ZERO_TWRCNT    : std_logic_vector(0 to 4) := (others => '0');
constant ZERO_TLZCNT    : std_logic_vector(0 to 4) := (others => '0');
constant ZERO_TRDCNT    : std_logic_vector(0 to 4) := (others => '0');
constant ZERO_TPACCCNT  : std_logic_vector(0 to 4) := (others => '0');
constant ZERO_THZCNT    : std_logic_vector(0 to 4) := (others => '0');

-------------------------------------------------------------------------------
-- Signal declarations
-------------------------------------------------------------------------------
signal twr_cnt          : std_logic_vector(0 to 4);
signal tlz_cnt          : std_logic_vector(0 to 4);
signal trd_cnt          : std_logic_vector(0 to 4);
signal thz_cnt          : std_logic_vector(0 to 4);
signal tpacc_cnt        : std_logic_vector(0 to 4);


signal thz_cnt_en       : std_logic; 
signal tlz_cnt_en       : std_logic; 
-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin  

-------------------------------------------------------------------------------
-- Write Cycle Delay Counter
-------------------------------------------------------------------------------
    
TWRCNT_I: entity proc_common_v3_00_a.ld_arith_reg
    generic map (C_ADD_SUB_NOT  => false,
                 C_REG_WIDTH    => 5,
                 C_RESET_VALUE  => "11111",
                 C_LD_WIDTH     => 5,
                 C_LD_OFFSET    => 0,
                 C_AD_WIDTH     => 1,
                 C_AD_OFFSET    => 0
                )
    port map (   CK             => Clk,
                 RST            => Rst,
                 Q              => twr_cnt,   
                 LD             => Twr_data, 
                 AD             => "1",  
                 LOAD           => Twr_load,
                 OP             => Twr_cnt_en
                 );

-------------------------------------------------------------------------------
-- Write End to Data Low Impedance Counter
-------------------------------------------------------------------------------
tlz_cnt_en <= '0' when tlz_cnt = ZERO_TLZCNT
         else '1';

TLZCNT_I: entity proc_common_v3_00_a.ld_arith_reg
    generic map (C_ADD_SUB_NOT  => false,
                 C_REG_WIDTH    => 5,
                 C_RESET_VALUE  => ZERO_TLZCNT,
                 C_LD_WIDTH     => 5,
                 C_LD_OFFSET    => 0,
                 C_AD_WIDTH     => 1,
                 C_AD_OFFSET    => 0
                )
    port map (   CK             => Clk,
                 RST            => Rst,
                 Q              => tlz_cnt,   
                 LD             => Tlz_data, 
                 AD             => "1",  
                 LOAD           => Tlz_load,
                 OP             => tlz_cnt_en
                 );

-------------------------------------------------------------------------------
-- Read Cycle Delay Counter
-------------------------------------------------------------------------------
TRDCNT_I: entity proc_common_v3_00_a.ld_arith_reg
    generic map (C_ADD_SUB_NOT  => false,
                 C_REG_WIDTH    => 5,
                 C_RESET_VALUE  => "11111",
                 C_LD_WIDTH     => 5,
                 C_LD_OFFSET    => 0,
                 C_AD_WIDTH     => 1,
                 C_AD_OFFSET    => 0
                )
    port map (   CK             => Clk,
                 RST            => Rst,
                 Q              => trd_cnt,   
                 LD             => Trd_data, 
                 AD             => "1",  
                 LOAD           => Trd_load,
                 OP             => Trd_cnt_en
                 );
                 
-------------------------------------------------------------------------------
-- Page Read Cycle Delay Counter
-------------------------------------------------------------------------------
TPACCCNT_I: entity proc_common_v3_00_a.ld_arith_reg
    generic map (C_ADD_SUB_NOT  => false,
                 C_REG_WIDTH    => 5,
                 C_RESET_VALUE  => "11111",
                 C_LD_WIDTH     => 5,
                 C_LD_OFFSET    => 0,
                 C_AD_WIDTH     => 1,
                 C_AD_OFFSET    => 0
                )
    port map (   CK             => Clk,
                 RST            => Rst,
                 Q              => tpacc_cnt,   
                 LD             => Tpacc_data, 
                 AD             => "1",  
                 LOAD           => Tpacc_load,
                 OP             => Tpacc_cnt_en
                 );
                 
                 
             
-------------------------------------------------------------------------------
-- Read End to High Impedance Delay Counter
-------------------------------------------------------------------------------
thz_cnt_en <= '0' when thz_cnt = ZERO_THZCNT else 
              '1';
        
THZCNT_I: entity proc_common_v3_00_a.ld_arith_reg
    generic map (C_ADD_SUB_NOT  => false,
                 C_REG_WIDTH    => 5,
                 C_RESET_VALUE  => ZERO_THZCNT,
                 C_LD_WIDTH     => 5,
                 C_LD_OFFSET    => 0,
                 C_AD_WIDTH     => 1,
                 C_AD_OFFSET    => 0
                )
    port map (   CK             => Clk,
                 RST            => Rst,
                 Q              => thz_cnt,   
                 LD             => Thz_data, 
                 AD             => "1",  
                 LOAD           => Thz_load,
                 OP             => thz_cnt_en
                 );


-------------------------------------------------------------------------------
-- Generation of Counter End Signals 
-------------------------------------------------------------------------------

Twr_end <= '1' when twr_cnt = ZERO_TWRCNT or Synch_mem = '1' else
           '0' ;
           
Tlz_end <= '1' when tlz_cnt = ZERO_TLZCNT or Synch_mem = '1' else
           '0' ;

Trd_end <= '1' when trd_cnt = ZERO_TRDCNT or Synch_mem = '1' else
           '0' ;
           
thz_end <= '1' when thz_cnt = ZERO_THZCNT or Synch_mem = '1' else
           '0' ;
           
Tpacc_end <= '1' when tpacc_cnt = ZERO_TPACCCNT or Synch_mem = '1' else
           '0' ;    
       
end imp;
-------------------------------------------------------------------------------
-- End of File counters.vhd
-------------------------------------------------------------------------------
