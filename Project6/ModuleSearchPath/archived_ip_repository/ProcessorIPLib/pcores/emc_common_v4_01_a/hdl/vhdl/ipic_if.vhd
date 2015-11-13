-------------------------------------------------------------------------------
-- EMC - entity/architecture pair
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
-- Filename:        ipic_if.vhd
-- Description:     IPIC Interface
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
--      combinatorial signals:                  "*_cmb"
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
use ieee.std_logic_signed.all;
use ieee.std_logic_misc.all;
-------------------------------------------------------------------------------
-- Proc common package of the proc common library is used for ld_arith_reg
-- declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.ld_arith_reg;
-------------------------------------------------------------------------------
-- vcomponents package of the unisim library is used for the FDR component
-- declaration
-------------------------------------------------------------------------------
library unisim;
use unisim.vcomponents.all;
-------------------------------------------------------------------------------
-- Definition of Generics:
--  C_NUM_BANKS_MEM         -- Number of Memory Banks
--  C_IPIF_DWIDTH           -- Processor Data Bus Width
--
-- Definition of Ports:
--  Bus2IP_RNW              -- Processor read not write (1=Read, 0=Write)
--  Bus2IP_Mem_CS           -- Memory Channel Chip Select
--  Mem2Bus_RdAddrAck       -- Memory Read Cycle Address Acknowledge
--  Mem2Bus_WrAddrAck       -- Memory Write Cycle Address Acknowledge
--  Mem2Bus_RdAck           -- Memory Read Cycle Acknowledge
--  Mem2Bus_WrAck           -- Memory Write Cycle Acknowledge 
--  Mem2Bus_Data            -- Memory Read Data
--  Bus2Mem_RdReq           -- Read request was seen by mem_state_machine
--  Bus2Mem_WrReq           -- Write request was seen by mem_state_machine
--  Bus2Mem_CS              -- Memory is being accessed
--  IP2Bus_Data             -- Read data from memory device or register
--  IP2Bus_errAck           -- Error acknowledge
--  IP2Bus_retry            -- Retry indicator
--  IP2Bus_toutSup          -- Suppress watch dog timer
--  IP2Bus_RdAck            -- Read acknowledge
--  IP2Bus_WrAck            -- Write acknowledge
--  IP2Bus_AddrAck          -- Address acknowledge
--  Burst_length            -- Count of current burst length
--  Transaction_done        -- Operation complete indication for current
--                          -- transaction
--  Bus2IP_Clk              -- System clock
--  Bus2IP_Reset            -- System Reset
-------------------------------------------------------------------------------
-- Port declarations
-------------------------------------------------------------------------------

entity ipic_if is
    generic (
        C_NUM_BANKS_MEM     : integer := 2;
        C_SPLB_DWIDTH       : integer := 32;
        C_IPIF_DWIDTH       : integer := 64     
    );
    port (
        Bus2IP_RNW          : in  std_logic;
        Bus2IP_Mem_CS       : in  std_logic_vector(0 to C_NUM_BANKS_MEM-1);
        
        Mem2Bus_RdAddrAck   : in  std_logic;
        Mem2Bus_WrAddrAck   : in  std_logic;
        Mem2Bus_RdAck       : in  std_logic;
        Mem2Bus_WrAck       : in  std_logic;
        Mem2Bus_Data        : in  std_logic_vector(0 to C_IPIF_DWIDTH - 1);

        Bus2Mem_CS          : out std_logic;
        Bus2Mem_RdReq       : out  std_logic;
        Bus2Mem_WrReq       : out  std_logic;
       
        IP2Bus_Data         : out std_logic_vector(0 to C_IPIF_DWIDTH - 1);
        IP2Bus_errAck       : out std_logic;
        IP2Bus_retry        : out std_logic;
        IP2Bus_toutSup      : out std_logic;
        IP2Bus_RdAck        : out std_logic;
        IP2Bus_WrAck        : out std_logic;
        IP2Bus_AddrAck      : out std_logic;
        
        Burst_length        : in  std_logic_vector(0 to log2(16*(
                                                        C_SPLB_DWIDTH/8)));
        Transaction_done    : in  std_logic;
        
        Bus2IP_Clk          : in  std_logic;
        Bus2IP_Reset        : in  std_logic
    );
end entity ipic_if;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture imp of ipic_if is

-------------------------------------------------------------------------------
-- Constant Declaration
-------------------------------------------------------------------------------
constant BURST_CNT_WIDTH      : integer := ((log2(16*(C_SPLB_DWIDTH/8))) + 1);
constant ZERO_CNT             : std_logic_vector(0 to BURST_CNT_WIDTH -1)
                                                             := (others=>'0');
-------------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------------

signal bus2mem_cs_i           : std_logic;
signal burst_cnt_en           : std_logic;
signal burst_cnt_ld_cmb       : std_logic;
signal pend_wrreq             : std_logic;
signal set_pend_wrreq         : std_logic;
signal clear_pend_wrreq       : std_logic;

signal pend_rdreq             : std_logic;
signal set_pend_rdreq         : std_logic;
signal clear_pend_rdreq       : std_logic;

signal burst_cnt_i            : std_logic_vector(0 to BURST_CNT_WIDTH - 1);

signal int_wrreq              : std_logic;
signal int_rdreq              : std_logic;
        ---remove this signal once fix is made to ipif
signal burst_length_i         :std_logic_vector(0 to BURST_CNT_WIDTH - 1);
signal bus2ip_mem_cs_reg      :std_logic_vector(0 to C_NUM_BANKS_MEM-1);
-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin -- architecture IMP

    ---------------------------------------------------------------------------
    -- IPIC 
    ---------------------------------------------------------------------------
    burst_length_i      <='0'&Burst_length(1 to BURST_CNT_WIDTH - 1);
    bus2Mem_CS_i        <= or_reduce(bus2IP_Mem_CS_reg);
    Bus2Mem_CS          <= bus2Mem_CS_i; 
    IP2Bus_errAck       <= '0';
    IP2Bus_retry        <= '0';
    IP2Bus_toutSup      <= bus2Mem_CS_i;
    IP2Bus_Data         <= Mem2Bus_Data;
    int_wrreq           <= not Bus2IP_RNW and bus2Mem_CS_i; 
    int_rdreq           <= Bus2IP_RNW and bus2Mem_CS_i;  

    ---------------------------------------------------------------------------
    -- Register the Bus2IP_Mem_CS
    ---------------------------------------------------------------------------

    CS_REG_PROCESS : process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1') then
            if(Bus2IP_Reset = '1')then
                bus2IP_Mem_CS_reg  <= (others=>'0');
            else
                bus2IP_Mem_CS_reg  <= Bus2IP_Mem_CS;
        end if;   
        end if;     
    end process CS_REG_PROCESS;


    ---------------------------------------------------------------------------
    -- Register the acks signals
    ---------------------------------------------------------------------------

    ACK_REG_PROCESS : process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1') then
            if(Bus2IP_Reset = '1')then
                IP2Bus_AddrAck  <= '0';
                IP2Bus_RdAck    <= '0';
                IP2Bus_WrAck    <= '0';
            else
                IP2Bus_AddrAck  <= Mem2Bus_RdAddrAck or Mem2Bus_WrAddrAck;
                IP2Bus_RdAck    <= Mem2Bus_RdAck;
                IP2Bus_WrAck    <= Mem2Bus_WrAck;
        end if;   
        end if;     
    end process ACK_REG_PROCESS;

    ---------------------------------------------------------------------------
    -- Burst length counter instantiation
    ---------------------------------------------------------------------------
        BURST_CNT: entity proc_common_v3_00_a.ld_arith_reg
            generic map (C_ADD_SUB_NOT  => false,
                         C_REG_WIDTH    => BURST_CNT_WIDTH,
                         C_RESET_VALUE  => ZERO_CNT,
                         C_LD_WIDTH     => BURST_CNT_WIDTH,
                         C_LD_OFFSET    => 0,
                         C_AD_WIDTH     => 1,
                         C_AD_OFFSET    => 0
                        )
            port map (   CK             => Bus2IP_Clk,
                         RST            => Bus2IP_Reset,
                         Q              => burst_cnt_i,   
                         LD             => burst_length_i, 
                         AD             => "1",  
                         LOAD           => burst_cnt_ld_cmb,
                         OP             => burst_cnt_en
                         );

    ---------------------------------------------------------------------------
    -- Burst length counter control signals
    ---------------------------------------------------------------------------
    burst_cnt_en      <= Mem2Bus_RdAddrAck or Mem2Bus_WrAddrAck;
    burst_cnt_ld_cmb  <= Transaction_done and bus2Mem_CS_i;

    ---------------------------------------------------------------------------
    -- Generation of pend_wrreq
    ---------------------------------------------------------------------------

    set_pend_wrreq   <= (not pend_wrreq) and Transaction_done and int_wrreq;
    clear_pend_wrreq <= '1' when (burst_cnt_i = 0) and 
                                        (Mem2Bus_WrAddrAck = '1') else
                        '0' ; 

    WRREQ_PROCESS : process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1') then
            if(Bus2IP_Reset = '1')then
                pend_wrreq  <= '0';
            elsif set_pend_wrreq ='1' then
                pend_wrreq  <= '1';
            elsif clear_pend_wrreq = '1' then
                pend_wrreq  <= '0';       
        end if;   
        end if;     
    end process WRREQ_PROCESS;

    Bus2Mem_WrReq  <= pend_wrreq;

    ---------------------------------------------------------------------------
    -- Generation of pend_rdreq
    ---------------------------------------------------------------------------

    set_pend_rdreq   <= (not pend_rdreq) and Transaction_done 
                                and int_rdreq;
    clear_pend_rdreq <= '1' when (burst_cnt_i = 0) and 
                                (Mem2Bus_RdAddrAck = '1') else
                        '0' ; 

    RDREQ_PROCESS : process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'EVENT and Bus2IP_Clk = '1') then
            if(Bus2IP_Reset = '1')then
                pend_rdreq  <= '0';
            elsif set_pend_rdreq ='1' then
                pend_rdreq  <= '1';
            elsif clear_pend_rdreq = '1' then
                pend_rdreq  <= '0';       
        end if;   
        end if;     
    end process RDREQ_PROCESS;

    Bus2Mem_RdReq  <= pend_rdreq;

end imp;
-------------------------------------------------------------------------------
-- End of File ipic_if.vhd
-------------------------------------------------------------------------------
