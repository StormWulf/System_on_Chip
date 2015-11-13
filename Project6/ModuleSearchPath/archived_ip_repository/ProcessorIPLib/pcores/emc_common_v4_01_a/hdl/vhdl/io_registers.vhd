-------------------------------------------------------------------------------
-- io_registers.vhd - entity/architecture pair
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
-- Filename:        io_registers.vhd
-- Description:     This file contains the IO registers for the EMC 
--                  design.
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
-- This file is based on version v2_01_c updated to fixed CR #466745: -
-- Added generic C_MEM_DQ_CAPTURE_NEGEDGE. This is used to cpture the Mem_DQ_I
-- 1. If C_MEM_DQ_CAPTURE_NEGEDGE=0 Mem_DQ_I will be captured on +ve edge 
--    (same as version v2_01_c) 
-- 2. If C_MEM_DQ_CAPTURE_NEGEDGE=1 Mem_DQ_I will be captured on -ve edge (new)
-- ~~~~~~~~~
-- NSK         02/12/08    Updated
-- ^^^^^^^^
-- Added generic C_MEM_DQ_CAPTURE_NEGEDGE in comment "Definition of Generics" 
-- section.
-- ~~~~~~~~
-- NSK         03/03/08    Updated
-- ^^^^^^^^
-- 1. Removed generic C_MEM_DQ_CAPTURE_NEGEDGE.
-- 2. Added the port RdClk used as clock to capture the data from memory.
-- ~~~~~~~~
-- NSK         05/08/08    version v3_00_a
-- ^^^^^^^^
-- 1. This file is same as in version v2_02_a.
-- 2. Upgraded to version v3.00.a to have proper versioning to fix CR #472164.
-- 3. No change in design.
-- ~~~~~~~~
-- ^^^^^^^^
-- KSB         08/08/08    version v4_00_a
-- 1. This file is same as in version v3_00_a.
-- 2. Upgraded to version v4.00.a 
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

-------------------------------------------------------------------------------
-- Definition of Generics:
--     C_INCLUDE_NEGEDGE_IOREGS -- include negative edge IO registers
--     C_IPIF_AWIDTH            -- width of processor address bus
--     C_MAX_MEM_WIDTH          -- maximum data width of memory banks
--     C_NUM_BANKS_MEM          -- number of memory banks
--
-- Definition of Ports:
--  -- Internal memory signals
--     Mem_A_int                -- Internal Memory address inputs
--     Mem_DQ_I_int             -- Internal Memory input data bus
--     Mem_DQ_O_int             -- Internal Memory output data bus
--     Mem_DQ_T_int             -- Internal Memory data output enable
--     Mem_CEN_int              -- Internal Memory chip select
--     Mem_OEN_int              -- Internal Memory output enable
--     Mem_WEN_int              -- Internal Memory write enable
--     Mem_QWEN_int             -- Internal Memory qualified write enable
--     Mem_BEN_int              -- Internal Memory byte enables
--     Mem_RPN_int              -- Internal Memory reset/power down
--     Mem_CE_int               -- Internal Memory chip enable
--     Mem_ADV_LDN_int          -- Internal Memory counter 
--                                 advance/load (=0)
--     Mem_LBON_int             -- Internal Memory linear/interleaved 
--                                 burst order (=0)
--     Mem_CKEN_int             -- Internal Memory clock enable (=0)
--     Mem_RNW_int              -- Internal Memory read not write
--
--  -- Memory signals
--     Mem_A                    -- Memory address inputs
--     Mem_DQ_I                 -- Memory input data bus
--     Mem_DQ_O                 -- Memory output data bus
--     Mem_DQ_T                 -- Memory data output enable
--     Mem_CEN                  -- Memory chip select
--     Mem_OEN                  -- Memory output enable
--     Mem_WEN                  -- Memory write enable
--     Mem_QWEN                 -- Memory qualified write enable
--     Mem_BEN                  -- Memory byte enables
--     Mem_RPN                  -- Memory reset/power down
--     Mem_CE                   -- Memory chip enable
--     Mem_ADV_LDN              -- Memory counter advance/load (=0)
--     Mem_LBON                 -- Memory linear/interleaved burst 
--                                 order (=0)
--     Mem_CKEN                 -- Memory clock enable (=0)
--     Mem_RNW                  -- Memory read not write
--
-- --- Clock & Reset
--     Clk                      -- System Clock
--     RdClk                    -- Read Clock
--     Rst                      -- System Reset
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity io_registers is
    generic ( 
        C_INCLUDE_NEGEDGE_IOREGS : integer range 0 to 1;
        C_IPIF_AWIDTH            : integer;
        C_MAX_MEM_WIDTH          : integer;
        C_NUM_BANKS_MEM          : integer
    );
  port (
      -- Internal memory signals
      Mem_A_int       : in  std_logic_vector(0 to C_IPIF_AWIDTH-1);
      Mem_DQ_I_int    : out std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
      Mem_DQ_O_int    : in  std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
      Mem_DQ_T_int    : in  std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
      Mem_CEN_int     : in  std_logic_vector(0 to C_NUM_BANKS_MEM-1);
      Mem_OEN_int     : in  std_logic_vector(0 to C_NUM_BANKS_MEM-1);
      Mem_WEN_int     : in  std_logic;
      Mem_QWEN_int    : in  std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
      Mem_BEN_int     : in  std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
      Mem_RPN_int     : in  std_logic;
      Mem_CE_int      : in  std_logic_vector(0 to C_NUM_BANKS_MEM-1);
      Mem_ADV_LDN_int : in  std_logic;
      Mem_LBON_int    : in  std_logic;
      Mem_CKEN_int    : in  std_logic;
      Mem_RNW_int     : in  std_logic;

      Mem_Addr_rst    : in  std_logic;

      -- Memory signals
      Mem_A           : out std_logic_vector(0 to C_IPIF_AWIDTH-1);
      Mem_DQ_I        : in  std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
      Mem_DQ_O        : out std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
      Mem_DQ_T        : out std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
      Mem_CEN         : out std_logic_vector(0 to C_NUM_BANKS_MEM-1);
      Mem_OEN         : out std_logic_vector(0 to C_NUM_BANKS_MEM-1);
      Mem_WEN         : out std_logic;
      Mem_QWEN        : out std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
      Mem_BEN         : out std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
      Mem_RPN         : out std_logic;
      Mem_CE          : out std_logic_vector(0 to C_NUM_BANKS_MEM-1);
      Mem_ADV_LDN     : out std_logic;
      Mem_LBON        : out std_logic;
      Mem_CKEN        : out std_logic;
      Mem_RNW         : out std_logic;

      -- Clock & Reset
      Clk             : in  std_logic;
      RdClk           : in  std_logic;
      Rst             : in  std_logic
    );
end entity io_registers;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture imp of io_registers is
-------------------------------------------------------------------------------
-- Constant declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal declarations
-------------------------------------------------------------------------------
signal mem_a_reg       : std_logic_vector(0 to C_IPIF_AWIDTH-1);
signal mem_dq_o_reg    : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal mem_dq_t_reg    : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal mem_cen_reg     : std_logic_vector(0 to C_NUM_BANKS_MEM-1);
signal mem_oen_reg     : std_logic_vector(0 to C_NUM_BANKS_MEM-1);
signal mem_wen_reg     : std_logic;
signal mem_qwen_reg    : std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
signal mem_ben_reg     : std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
signal mem_rpn_reg     : std_logic;
signal mem_ce_reg      : std_logic_vector(0 to C_NUM_BANKS_MEM-1);
signal mem_adv_ldn_reg : std_logic;
signal mem_lbon_reg    : std_logic;
signal mem_cken_reg    : std_logic;
signal mem_rnw_reg     : std_logic;


-------------------------------------------------------------------------------
-- Component declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin 
-------------------------------------------------------------------------------
-- OUTPUTS
-------------------------------------------------------------------------------
    
-------------------------------------------------------------------------------
-- Instantiate the positive clock edge output register.
-- This is always present due to combinational logic on the memory control 
-- signals.
-------------------------------------------------------------------------------

POSEDGE_OUTPUTREGS_PROCESS: process(Clk)
begin
    if Clk'event and Clk = '1' then
        if Rst = '1' then
            mem_dq_o_reg    <= (others => '0');
            mem_dq_t_reg    <= (others => '1');
            mem_cen_reg     <= (others => '1');
            mem_oen_reg     <= (others => '1');
            mem_wen_reg     <= '1';
            mem_qwen_reg    <= (others => '1');
            mem_ben_reg     <= (others => '1');
            mem_rpn_reg     <= '0';
            mem_ce_reg      <= (others => '0');
            mem_adv_ldn_reg <= '0';
            mem_lbon_reg    <= '0';
            mem_cken_reg    <= '0';
            mem_rnw_reg     <= '0';
        else
            mem_dq_o_reg    <= Mem_DQ_O_int;
            mem_dq_t_reg    <= Mem_DQ_T_int;
            mem_cen_reg     <= Mem_CEN_int;
            mem_oen_reg     <= Mem_OEN_int;
            mem_wen_reg     <= Mem_WEN_int;
            mem_qwen_reg    <= Mem_QWEN_int;
            mem_ben_reg     <= Mem_BEN_int;
            mem_rpn_reg     <= Mem_RPN_int;
            mem_ce_reg      <= Mem_CE_int;
            mem_adv_ldn_reg <= Mem_ADV_LDN_int;
            mem_lbon_reg    <= Mem_LBON_int;
            mem_cken_reg    <= Mem_CKEN_int;
            mem_rnw_reg     <= Mem_RNW_int;
        end if;
    end if;
end process POSEDGE_OUTPUTREGS_PROCESS;

-------------------------------------------------------------------------------
-- MEM_ADDR_PROCESS: This process is added to fix CR: 214725
--
-------------------------------------------------------------------------------
MEM_ADDR_PROCESS: process(clk)
begin
    if Clk'event and Clk = '1' then
        if (Mem_Addr_rst = '1') then
            mem_a_reg <= (others => '0');
	else
	    mem_a_reg <= Mem_A_int;
	end if;
    end if;
end process MEM_ADDR_PROCESS;

-------------------------------------------------------------------------------
-- Instantiate the negative clock edge output register if design has been
-- configured to do so.
-------------------------------------------------------------------------------

NEGEDGE_OUTPUT_REGS_GEN: if C_INCLUDE_NEGEDGE_IOREGS = 1 generate
begin
    NEGEDGE_OUTPUTREGS_PROCESS: process(Clk)
    begin
        if Clk'event and Clk = '0' then
            if Rst = '1' then
                Mem_A       <= (others => '0');
                Mem_DQ_O    <= (others => '0');
                Mem_DQ_T    <= (others => '1');
                Mem_CEN     <= (others => '1');
                Mem_OEN     <= (others => '1');
                Mem_WEN     <= '1';
                Mem_QWEN    <= (others => '1');
                Mem_BEN     <= (others => '1');
                Mem_RPN     <= '0';
                Mem_CE      <= (others => '0');
                Mem_ADV_LDN <= '0';
                Mem_LBON    <= '0';
                Mem_CKEN    <= '0';
                Mem_RNW     <= '0';
            else
                Mem_A       <= mem_a_reg;
                Mem_DQ_O    <= mem_dq_o_reg;
                Mem_DQ_T    <= mem_dq_t_reg;
                Mem_CEN     <= mem_cen_reg;
                Mem_OEN     <= mem_oen_reg;
                Mem_WEN     <= mem_wen_reg;
                Mem_QWEN    <= mem_qwen_reg;
                Mem_BEN     <= mem_ben_reg;
                Mem_RPN     <= mem_rpn_reg;
                Mem_CE      <= mem_ce_reg;
                Mem_ADV_LDN <= mem_adv_ldn_reg;
                Mem_LBON    <= mem_lbon_reg;
                Mem_CKEN    <= mem_cken_reg;
                Mem_RNW     <= mem_rnw_reg;
            end if;
        end if;
    end process NEGEDGE_OUTPUTREGS_PROCESS;
end generate NEGEDGE_OUTPUT_REGS_GEN;

-------------------------------------------------------------------------------
-- Pass the values through if there are no negative io registers
-------------------------------------------------------------------------------
NO_NEGEDGE_OUTPUT_REGS_GEN: if C_INCLUDE_NEGEDGE_IOREGS = 0 generate
begin
    Mem_A       <= mem_a_reg;
    Mem_DQ_O    <= mem_dq_o_reg;
    Mem_DQ_T    <= mem_dq_t_reg;
    Mem_CEN     <= mem_cen_reg;
    Mem_OEN     <= mem_oen_reg;
    Mem_WEN     <= mem_wen_reg;
    Mem_QWEN    <= mem_qwen_reg;
    Mem_BEN     <= mem_ben_reg;
    Mem_RPN     <= mem_rpn_reg;
    Mem_CE      <= mem_ce_reg;
    Mem_ADV_LDN <= mem_adv_ldn_reg;
    Mem_LBON    <= mem_lbon_reg;
    Mem_CKEN    <= mem_cken_reg;
    Mem_RNW     <= mem_rnw_reg;
end generate NO_NEGEDGE_OUTPUT_REGS_GEN;

-------------------------------------------------------------------------------
-- Registers the input memory data port signals.
-------------------------------------------------------------------------------
INPUTREGS_PROCESS: process(RdClk)
begin
    if RdClk'event and RdClk = '1' then
        if Rst = '1' then
            Mem_DQ_I_int <= (others => '0');
        else
            Mem_DQ_I_int <= Mem_DQ_I;
        end if;
    end if;
end process INPUTREGS_PROCESS;


end architecture imp;
-------------------------------------------------------------------------------
-- End of File io_registers.vhd.
-------------------------------------------------------------------------------
