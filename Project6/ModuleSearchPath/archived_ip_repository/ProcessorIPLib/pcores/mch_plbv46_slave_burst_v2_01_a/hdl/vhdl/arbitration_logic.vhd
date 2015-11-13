-------------------------------------------------------------------------------
-- arbitration_logic.vhd - entity/architecture pair
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
-- Filename:        arbitration_logic.vhd
-- Version:         v2.01a
-- Description:     
--                  This file contains the arbitration logic for the 
--                  MCH_PLBV46_SLAVE_BURST. Only fixed priority arbitration is 
--                  supported in this release. The priority is as follows:
--
--                  MCH interface 0  -- highest priority
--                  MCH interface 1  -- next highest priority
--                      --
--                  MCH interface n  -- second to lowest priority
--                  PLBV46 interface    -- lowest priority
--
--                  If the PLBV46 interface exists, it is at lowest priority.If
--                  it does not exist, MCH interface n is at lowest priority.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  -- mch_plbv46_slave_burst.vhd                  
--                      -- mch_interface.vhd
--                          -- access_buffer.vhd
--                          -- readdata_buffer.vhd
--                          -- chnl_logic.vhd
--                          -- addr_be_gen.vhd
--                          -- ipic_logic.vhd
--                      -- arb_mux_demux.vhd
--                          -- addr_data_mux_demux.vhd
--                          -- arbitration_logic.vhd
--                      -- plbv46_slave_burst.vhd
--                      
-------------------------------------------------------------------------------
-- Author:      PVK
-- History:
--  PVK         11/02/06        First version
-- ^^^^^^
--  First version of mch_plbv46_slave_burst
--  Integrated this code in mch_plbv46_slave_burst
-- ~~~~~~
--  ALS         11/02/06
-- ^^^^^^
--  Modified generation of burst_arb_cycle to be based off burst counter.
-- ~~~~~~~
--  ALS         11/10/06
-- ^^^^^^
--  Modified generation of burst_arb_cycle to be based off state machine.
-- ~~~~~~~
--  PVK         02/26/07
-- ^^^^^^
-- Removed port Hold_Burst. Comment cleanup.
-- ~~~~~~
--  NSK         06/28/07
-- ^^^^^^
-- To close the CR # 441978 added signal cs_equal to the sensitivity list of 
-- proces: ADDR_MUX_SELECT_PROCESS.
-- ~~~~~~
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
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- library unsigned is used for overloading of "=" which allows integer to
-- be compared to std_logic_vector
-------------------------------------------------------------------------------
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- library misc is used for or_reduce function
-------------------------------------------------------------------------------
use ieee.std_logic_misc.all;

-------------------------------------------------------------------------------
-- The proc_common library is required to instantiate mux_onehot_f component
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.mux_onehot_f;

-------------------------------------------------------------------------------
-- The unisim library is required to instantiate Xilinx primitives.
-------------------------------------------------------------------------------
library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Definition of Generics:
--  C_NUM_MASTERS              -- number of masters
--  C_NUM_CHANNELS             -- number of MCH interfaces
--  C_PRIORITY_MODE            -- dynamic or fixed priority
--  C_NUM_MCH_CS               -- number of CSs supported by the MCH interfaces
--  C_NUM_PLB_CS               -- number of CSs supported by PLBV46
--  C_INCLUDE_PLB_IPIF         -- indicates if PLBV46  is included
--  C_BRSTCNT_WIDTH            -- burst count width  
--  C_FAMILY                   -- target FPGA family
--
-- Definition of Ports:
--         
--  -- System signals
--  Sys_Clk
--  Sys_Rst
--
--  Chnl_Req                -- bus of Channel request signals
--  PLB2IP_CS               -- bus of PLBV462IP Chip Selects
--  Chnl_Data_Almost_Done   -- indicates a channel's data phase is almost done
--  Chnl_Addr_Almost_Done   -- indicates a channel's addr phase is almost done
--  Bus2IP_Burst            -- indicates there is more valid data
--  PLB2IP_Burst            -- PLBV46 burst request indicating there is more 
--                             valid data
--  IP2Bus_AddrAck          -- address acknowledge
--  IP2Bus_RdAck            -- read data acknowledge
--  IP2Bus_WrAck            -- write data acknowledge 
--  IP2Bus_Error            -- indicates that there was a data phase timeout
--  CS_Bus                  -- Channel and PLBV46 Chip Selects
--  Bus2IP_CS               -- Chip Selects of current transaction
--  PLB_Request             -- registered OR reduce of PLBV46 Chip Selects
--  PLB_Request_Gated       -- registered PLBV46 Request gated off when PLBV46 
--                             wins arbitration
--  PLB_xfer_end            -- end of current PLBV46 transaction
--  IPIC_Addr_Mux_Sel       -- address mux select
--  IPIC_Data_Mux_Sel       -- data mux select
--  Addr_Master             -- address phase master             
--  Data_Master             -- data phase master 
--  Addr_arb_cycle          -- address phase arbitration cycle
--  Data_arb_cycle          -- data phase arbitration cycle
--  Addr_phase_idle         -- current state of the address phase
--  Data_phase_idle         -- current state of the data phase
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity arbitration_logic is
  generic(  C_NUM_MASTERS       : integer   := 3;
            C_NUM_CHANNELS      : integer   := 3;
            C_PRIORITY_MODE     : integer   := 0;  -- only fixed priority supported
            C_NUM_MCH_CS        : integer   := 1;
            C_NUM_PLB_CS        : integer   := 1;
            C_INCLUDE_PLB_IPIF  : integer   := 0;
            C_BRSTCNT_WIDTH     : integer   := 6; 
            C_FAMILY            : string    := "nofamily"
         );
  port (
        Sys_Clk                 : in  std_logic;
        Sys_Rst                 : in  std_logic;

        Chnl_Req                : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        PLB2IP_CS               : in  std_logic_vector(0 to C_NUM_PLB_CS-1);
        Chnl_Data_Almost_Done   : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        Chnl_Addr_Almost_Done   : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
                                  
        Bus2IP_Burst            : in  std_logic;
        PLB2IP_Burst            : in  std_logic;
        IP2Bus_AddrAck          : in  std_logic;
        IP2Bus_RdAck            : in  std_logic;
        IP2Bus_WrAck            : in  std_logic;
        
        IP2Bus_Error            : in  std_logic;
        
        CS_Bus                  : in  std_logic_vector(0 to 
                                        C_NUM_MASTERS*C_NUM_MCH_CS-1);
        Bus2IP_CS               : in  std_logic_vector(0 to C_NUM_PLB_CS-1);
        
        PLB_Request             : out std_logic;
        PLB_Request_Gated       : out std_logic;
        PLB_xfer_end            : out std_logic;
        
        IPIC_Addr_Mux_Sel       : out std_logic_vector(0 to C_NUM_MASTERS-1);
        IPIC_Data_Mux_Sel       : out std_logic_vector(0 to C_NUM_MASTERS-1);
        Addr_Master             : out std_logic_vector(0 to C_NUM_MASTERS-1);
        Data_Master             : out std_logic_vector(0 to C_NUM_MASTERS-1);

        Addr_arb_cycle          : out std_logic;
        Data_arb_cycle          : out std_logic;

        Addr_phase_idle         : out std_logic;
        Data_phase_idle         : out std_logic

        );
  
end arbitration_logic;


-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of arbitration_logic is
-------------------------------------------------------------------------------
-- Signal and Type Declarations
------------------------------------------------------------------------------- 
-- Determine if any request is asserted and concatenate all requests to a 
-- single bus
signal any_request  : std_logic;
signal m_request    : std_logic_vector(0 to C_NUM_MASTERS-1);

-- Need active low request signals to properly drive select lines of muxes 
signal req_n        : std_logic_vector(0 to C_NUM_MASTERS-1) := (others => '0');

-- PLB request
signal plb_request_cmb      : std_logic; -- OR of PLB CS
signal plb_request_gated_i  : std_logic; -- PLB CS gated off when PLB is master
signal plb_request_i        : std_logic; -- registered plb_request_cmb

-- declare a 2-dimensional array for each master's priority level and mux chain
type MASTER_LVL_TYPE is array(0 to C_NUM_MASTERS-1) of std_logic_vector(0 to 
                                                              C_NUM_MASTERS-1);
signal m_muxout             : MASTER_LVL_TYPE;  -- output of each MUXCY

-- internal intermediate grant signals
signal grant_i              : std_logic_vector(0 to C_NUM_MASTERS-1);

-- Address Phase State Machine signals
type ADDR_PHASE_STATE_TYPE  is (ADDR_IDLE, ADDR_BUSY, ADDR_ARB_NULL_CYCLE);
signal addr_phase_cs        : ADDR_PHASE_STATE_TYPE := ADDR_IDLE;
signal addr_phase_ns        : ADDR_PHASE_STATE_TYPE := ADDR_IDLE;

signal addr_phase_idle_cmb  : std_logic;
signal data_phase_idle_cmb  : std_logic;
signal addr_phase_idle_i    : std_logic;
signal data_phase_idle_i    : std_logic;

-- Data Phase State Machine signals
type DATA_PHASE_STATE_TYPE  is (DATA_IDLE, DATA_BUSY, DATA_ARB_NULL_CYCLE);
signal data_phase_cs        : DATA_PHASE_STATE_TYPE := DATA_IDLE;
signal data_phase_ns        : DATA_PHASE_STATE_TYPE := DATA_IDLE;

-- Burst Arbitration State Machine signals
type BURST_ARB_STATE_TYPE  is (BURST_IDLE, BURST_BUSY, BURST_ARB_NULL_CYCLE);
signal burst_arb_ns         : BURST_ARB_STATE_TYPE := BURST_IDLE;

-- Data Master State Machine signals
type DATA_MASTER_STATE_TYPE  is ( IDLE, ONE_AHEAD, TWO_AHEAD );
signal data_master_cs       : DATA_MASTER_STATE_TYPE := IDLE;
signal data_master_ns       : DATA_MASTER_STATE_TYPE := IDLE;

-- arbitration cycle signals
signal addr_arb_cycle_i     : std_logic;
signal data_arb_cycle_i     : std_logic;
signal addr_arb_cycle_d1    : std_logic;
signal data_arb_cycle_d1    : std_logic;
signal addr_arb_cycle_fe    : std_logic;
signal data_arb_cycle_fe    : std_logic;
signal mch_addr_almost_done : std_logic;
signal mch_data_almost_done : std_logic;
signal plb_addr_xfer_end    : std_logic;
signal plb_data_xfer_end    : std_logic;
signal null_arb_cycle       : std_logic;
signal ip2bus_ack_i         : std_logic;

-- address and multiple data phase masters
signal addr_master_i        : std_logic_vector(0 to C_NUM_MASTERS-1);
signal data_master_i        : std_logic_vector(0 to C_NUM_MASTERS-1);
signal old_data_master_i    : std_logic_vector(0 to C_NUM_MASTERS-1);
signal next_data_master_i   : std_logic_vector(0 to C_NUM_MASTERS-1);
signal second_data_master_i : std_logic_vector(0 to C_NUM_MASTERS-1);


signal addr_one_ahead_data  : std_logic;
signal addr_two_ahead_data  : std_logic;

signal ld_next_data_master       : std_logic; 
signal ld_next_data_master_com   : std_logic;

signal ld_second_data_master     : std_logic; 
signal ld_second_data_master_com : std_logic;

-------------------------------------------------------------------------------
-- Reduction OR function.
-------------------------------------------------------------------------------
function or_reduce (v : std_logic_vector) return std_logic is
    variable r : std_logic := '0';
begin
    for i in v'range loop
        r := r or v(i);
    end loop;
    return r;
end;

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin

-- Only fixed priority mode is supported at this time, therefore, everything
-- is inside a generate for C_PRIORITY_MODE=0
FIXED_PRIORITY_GEN: if C_PRIORITY_MODE = 0 generate
begin
    ---------------------------------------------------------------------------
    -- Assign output signals to internal signals
    ---------------------------------------------------------------------------
    Addr_master         <= addr_master_i;
    Data_master         <= data_master_i;

    Addr_arb_cycle      <= addr_arb_cycle_i;
    Data_arb_cycle      <= data_arb_cycle_i;

    Addr_phase_idle     <= addr_phase_idle_i;
    Data_phase_idle     <= data_phase_idle_i;
    
    PLB_Request         <= plb_request_i;
    PLB_Request_Gated   <= plb_request_gated_i;
    
    PLB_xfer_end        <= plb_data_xfer_end;
    ip2bus_ack_i        <= IP2Bus_RdAck or IP2Bus_WrAck;
    
    ---------------------------------------------------------------------------
    -- Determine transaction requests - 
    ---------------------------------------------------------------------------    
    -- concatenate an PLB request to the channel request bus if PLB IPIF is 
    -- included plb_request is the OR of PLB2IP_CS and is gated off when PLB is
    -- granted the bus or when the arbitration logic has issued a reset
    PLB_REQ_GEN: if C_INCLUDE_PLB_IPIF = 1 generate
    
        plb_request_cmb <= or_reduce(PLB2IP_CS);
        
        -----------------------------------------------------------------------
        -- PLB_REQ_REG Process
        -- Gate off the PLB request when PLB becomes the master 
        -----------------------------------------------------------------------
        PLB_REQ_REG: process (Sys_Clk)
        begin
            if Sys_Clk'event and Sys_Clk = '1' then
                if Sys_Rst = '1' then
                    plb_request_i       <= '0';
                    plb_request_gated_i <= '0';
                else
                    plb_request_i       <= plb_request_cmb;
                    plb_request_gated_i <= plb_request_cmb and 
                                           not(addr_master_i(C_NUM_MASTERS-1));  
                end if;
            end if;
        end process PLB_REQ_REG;

        m_request      <= Chnl_Req & plb_request_gated_i;
    end generate PLB_REQ_GEN;
    
    NO_PLB_REQ_GEN: if C_INCLUDE_PLB_IPIF = 0 generate
        plb_request_cmb     <= '0';
        plb_request_gated_i <= '0';
        plb_request_i       <= '0';
        m_request           <= Chnl_Req;
    end generate NO_PLB_REQ_GEN;

    ---------------------------------------------------------------------------
    -- OR the requests together
    ---------------------------------------------------------------------------
    any_request <= or_reduce(m_request); 

    ---------------------------------------------------------------------------
    -- determine the correct Addr and Data Almost Done signals
    ---------------------------------------------------------------------------
    -- these can be OR'd together since a channel won't assert it unless it's
    -- the master of the transaction
    ---------------------------------------------------------------------------
    mch_addr_almost_done <= or_reduce(Chnl_Addr_Almost_Done);
    mch_data_almost_done <= or_reduce(Chnl_Data_Almost_Done);

    ---------------------------------------------------------------------------
    -- Determine the end of an PLB cycle (if the PLB IPIF is included)
    ---------------------------------------------------------------------------
    -- if PLB IPIF is included and the PLB is the master, then negation of 
    -- any_plb_cs is a cycle terminator as well as PLB2IP_Burst=0 and 
    -- IP2Bus_Ack = 1
    INCLUDE_PLB_XFEREND_GEN: if C_INCLUDE_PLB_IPIF = 1 generate
    begin

        plb_addr_xfer_end <= plb_data_xfer_end; 
                                
        plb_data_xfer_end <= '1' 
                        when (data_master_i(C_NUM_MASTERS-1)='1' and
                                ((PLB2IP_Burst='0' and ip2bus_ack_i='1')))                                 
                        else '0';
        
    end generate INCLUDE_PLB_XFEREND_GEN;
    
    NO_INCLUDE_PLB_XFEREND_GEN: if C_INCLUDE_PLB_IPIF = 0 generate
        plb_addr_xfer_end <= '0';                                            
        plb_data_xfer_end <= '0';                                            
    end generate NO_INCLUDE_PLB_XFEREND_GEN;
    
    ---------------------------------------------------------------------------
    -- determine the arbitration cycles for the address, burst, and data phases 
    -- of the transactions
    ---------------------------------------------------------------------------
    -- ADDR_PHASE_STATE_MACHINE and DATA_PHASE_STATE_MACHINE - these
    -- state machines keep track of the state (busy or idle) of the address 
    -- phase and data phase of the transaction. Both phases of the transaction 
    -- are considered "busy" as soon as there is a request. The address phase 
    -- is then considered "idle" once mch_addr_almost_done asserts or the PLB 
    -- xfer is done, and there are no new requests. 
    -- The data phase is considered "idle" when burst is negated, data 
    -- acknowledge is asserted, or the PLB xfer is done and there are no new 
    -- requests.
    ADDR_PHASE_STATE_MACHINE_CMB: process ( addr_phase_cs,
                                            any_request, 
                                            mch_addr_almost_done, 
                                            null_arb_cycle,
                                            plb_addr_xfer_end)
    begin
    addr_phase_idle_cmb <= '1';
    addr_arb_cycle_i    <= '1';
    addr_phase_ns       <= addr_phase_cs;
    
    case addr_phase_cs is
    ------------------------ ADDR_IDLE ---------------------------------
        when ADDR_IDLE =>    
             
            if any_request = '1'   then
                addr_phase_idle_cmb <= '0';
                addr_phase_ns <= ADDR_BUSY;
            end if;
             
    ------------------------ ADDR_BUSY ---------------------------------
        when ADDR_BUSY =>
        
            addr_phase_idle_cmb <= '0';
            addr_arb_cycle_i    <= '0';
            
            if plb_addr_xfer_end = '1' then
                -- wait for PLB data to finish 
                addr_phase_ns <= ADDR_ARB_NULL_CYCLE;
            end if;
            
            if mch_addr_almost_done = '1'  then
                addr_arb_cycle_i <= '1';
                if any_request = '0' then
                    addr_phase_idle_cmb <= '1';
                    addr_phase_ns       <= ADDR_IDLE;
                end if;
            end if;
    
    ------------------------ ADDR_ARB_NULL_CYCLE -----------------------
        when ADDR_ARB_NULL_CYCLE =>
            -- this is a null state after the end of an PLB xfer
            addr_arb_cycle_i <= '0';
            
            -- see if plb data is finished
            if null_arb_cycle = '1' then
                addr_phase_idle_cmb <= '1';
                addr_phase_ns <= ADDR_IDLE;
            end if;
    end case;
    end process ADDR_PHASE_STATE_MACHINE_CMB;


    ---------------------------------------------------------------------------
    -- Data Phase State Machine
    ---------------------------------------------------------------------------
    DATA_PHASE_STATE_MACHINE_CMB: process ( data_phase_cs,
                                            addr_one_ahead_data,
                                            any_request,
                                            addr_two_ahead_data,
                                            addr_phase_idle_i,
                                            mch_data_almost_done,
                                            plb_data_xfer_end)
    begin

    data_phase_idle_cmb <= '1';
    data_arb_cycle_i    <= '1';
    data_phase_ns       <= data_phase_cs;
    null_arb_cycle      <= '0';
    
    case data_phase_cs is
    
    --------------------------- DATA_IDLE -----------------------------------
        when DATA_IDLE =>    
         
            if (addr_one_ahead_data = '1' or addr_two_ahead_data = '1') then
                data_arb_cycle_i <= '0';
                data_phase_ns    <= DATA_BUSY;
            end if;
         
            if any_request = '1' or addr_phase_idle_i = '0' then
                data_phase_idle_cmb <= '0';
                data_phase_ns       <= DATA_BUSY;
            end if;
             
    ------------------------ DATA_BUSY --------------------------------------
        when DATA_BUSY =>
        
            data_phase_idle_cmb <= '0';
            data_arb_cycle_i    <= '0';
            
            
            if plb_data_xfer_end = '1' then
                data_phase_ns <= DATA_ARB_NULL_CYCLE;
            end if;
            
            if mch_data_almost_done = '1'  then
                data_arb_cycle_i <= '1';
                if any_request = '0'  and addr_one_ahead_data = '0' and  
                                              addr_two_ahead_data = '0' then
                    data_phase_idle_cmb <= '1';
                    data_phase_ns <= DATA_IDLE;
                end if;
            end if;
    ------------------------ DATA_ARB_NULL_CYCLE ----------------------------
        when DATA_ARB_NULL_CYCLE =>
        
             -- this is a null state after the end of an PLB xfer
            data_phase_idle_cmb <= '1';
            data_arb_cycle_i <= '0';
            data_phase_ns <= DATA_IDLE;

            -- assert signal so address phase state machine and data master
            -- state mahcine will move to IDLE state
            null_arb_cycle <= '1';

    end case;
    end process DATA_PHASE_STATE_MACHINE_CMB;
    

    ---------------------------------------------------------------------------
    -- Data Address Phase State Machine Registered Process
    ---------------------------------------------------------------------------
    DATA_ADDR_PHASE_SM_REG: process (Sys_Clk)
    begin
      if Sys_Clk'event and Sys_Clk = '1' then
          if Sys_Rst = '1' then
              data_phase_cs     <= DATA_IDLE;
              addr_phase_cs     <= ADDR_IDLE;
              
              data_phase_idle_i <= '1';
              addr_phase_idle_i <= '1';
              
              data_arb_cycle_d1 <= '0';
              addr_arb_cycle_d1 <= '0';
          else
              data_phase_cs     <= data_phase_ns;
              addr_phase_cs     <= addr_phase_ns;
             
              data_phase_idle_i <= data_phase_idle_cmb;
              addr_phase_idle_i <= addr_phase_idle_cmb;
              
              data_arb_cycle_d1 <= data_arb_cycle_i;
              addr_arb_cycle_d1 <= addr_arb_cycle_i;
          end if;
      end if;
    end process DATA_ADDR_PHASE_SM_REG;

    data_arb_cycle_fe <= '1' when data_arb_cycle_i = '0' and 
                                  data_arb_cycle_d1 = '1'
                             else '0';
                             
    addr_arb_cycle_fe <= '1' when addr_arb_cycle_i = '0' and 
                                  addr_arb_cycle_d1 = '1'
                             else '0';
    
    ---------------------------------------------------------------------------
    -- Determine the Master's grant signals
    ---------------------------------------------------------------------------
    MASTERLOOP: for i in 0 to C_NUM_MASTERS-1 generate

        req_n(i) <= not(m_request(i));

        -- for highest priority master, master 0, the request is the grant
        MASTER0_GRNT_GEN: if i = 0 generate
            grant_i(i) <= m_request(i);
        end generate MASTER0_GRNT_GEN;


        -- for other masters, use a MUXCY carry chain. The master's request
        -- starts the chain - it is gated off if a higher priority master's 
        -- request is asserted
        OTHER_MASTER_GRNTS_GEN: if i > 0 and i < C_NUM_MASTERS generate
        begin

            -- need to negate the request signals to provide the proper MUX
            -- selects
            MASTER_CARRYCHAIN_GEN: for j in 0 to i generate 
                                                     -- will need i+1 MUXCYs   
            begin

                -- first MUXCY uses the master's request to select '1' or '0'
                -- to send up the chain
                FIRSTMUX_GEN: if j = 0 generate
                    -- this mux selects either 0 if the master's not requesting
                    -- or 1 if the master is requesting - this value is sent
                    -- up the MUXCY chain and is only gated off if another
                    -- master's request of higher priority is asserted
                    FIRST_MUX_I: muxcy
                      port map (
                        O   =>  m_muxout(i)(j),   --[out]
                        CI  =>  '0',              --[in]
                        DI  =>  '1',              --[in]
                        S   =>  req_n(i-j)        --[in]
                        );
                end generate FIRSTMUX_GEN;

                OTHERMUX_GEN: if j /= 0 generate
                    OTHER_MUXES_I: MUXCY
                      port map (
                        O   =>  m_muxout(i)(j),   --[out]
                        CI  =>  m_muxout(i)(j-1), --[in]
                        DI  =>  '0',              --[in]
                        S   =>  req_n(i-j)        --[in]
                      );
                end generate OTHERMUX_GEN;

            end generate MASTER_CARRYCHAIN_GEN;

            grant_i(i) <= m_muxout(i)(i);

        end generate OTHER_MASTER_GRNTS_GEN;

    end generate MASTERLOOP;
       
    ---------------------------------------------------------------------------
    -- Register the grant signals during arbitration cycles
    ---------------------------------------------------------------------------
    ADDR_MASTER_REG: process (Sys_Clk)
    begin
        if Sys_Clk'event and Sys_Clk = '1' then
            -- ALS added null_arb_cycle to reset addr master
            if Sys_Rst = '1' or null_arb_cycle = '1' then
                addr_master_i <= (others => '0');
            elsif addr_arb_cycle_i = '1' then
                addr_master_i <= grant_i;
            end if;
        end if;
    end process ADDR_MASTER_REG;

    ---------------------------------------------------------------------------
    -- Register the data master signals during arbitration cycles
    ---------------------------------------------------------------------------
    -- if address arbitration phase, then data master is the grant signals
    -- if not address arbitration phase, then data master is the address master
    -- if address mux is one stage ahead of data mux, then data master is next 
    -- data master if address mux is two stages ahead of data mux, then data 
    -- master is second data master
    DATA_MASTER_REG: process (Sys_Clk)
    begin
        if Sys_Clk'event and Sys_Clk = '1' then
            -- ALS added null_arb_cycle to reset data master
            if Sys_Rst = '1' or null_arb_cycle = '1' then
                data_master_i <= (others => '0');                
            elsif data_arb_cycle_i = '1' then             
                if addr_two_ahead_data = '1' then
                    -- added check for loading second_data_master
                    if ld_second_data_master = '1' then
                        data_master_i <= next_data_master_i;
                    else
                        data_master_i <= second_data_master_i; 
                    end if;
                elsif addr_one_ahead_data = '1' then
                    -- added check for loading next_data master
                    if ld_next_data_master = '1' then
                        data_master_i <= addr_master_i;
                    else
                        data_master_i <= next_data_master_i; 
                    end if;
                elsif addr_arb_cycle_i = '1' then
                    data_master_i <= grant_i;                    
                else
                    data_master_i <= addr_master_i;
                end if;
            end if;
        end if;
    end process DATA_MASTER_REG;

    ---------------------------------------------------------------------------
    -- Next data master Registered Process
    ---------------------------------------------------------------------------
    NEXT_DATA_MASTER_REG: process (Sys_Clk)
    begin
        if Sys_Clk'event and Sys_Clk = '1' then
            if Sys_Rst = '1' then
                next_data_master_i <= (others => '0');            
            elsif ld_next_data_master = '1' or ld_second_data_master = '1' then
                next_data_master_i <= addr_master_i;            
            elsif data_arb_cycle_i = '1' then
            
                -- Add check if addr arb cycle is two ahead of data arb cycle
                if addr_arb_cycle_i = '1' and addr_two_ahead_data = '0' then
                    next_data_master_i <= grant_i;
                end if;
            end if;
        end if;
    end process NEXT_DATA_MASTER_REG;

    ---------------------------------------------------------------------------
    -- Second data master Registered Process
    ---------------------------------------------------------------------------
    SECOND_DATA_MASTER_REG: process (Sys_Clk)
    begin
        if Sys_Clk'event and Sys_Clk = '1' then
            if Sys_Rst = '1' then
                second_data_master_i <= (others => '0');            
            elsif ld_second_data_master = '1' then
                second_data_master_i <= next_data_master_i;            
            elsif data_arb_cycle_i = '1' then
                if addr_arb_cycle_i = '1' then
                    second_data_master_i <= grant_i;
                end if;
            end if;
        end if;
    end process SECOND_DATA_MASTER_REG;

    ---------------------------------------------------------------------------
    -- Data Master State Machine Registered Process
    ---------------------------------------------------------------------------
    -- Generates next data master signal.  Records advance progress of address
    -- master state to assign data master state.  Avoids missing any 
    -- assignments of data master.
    ---------------------------------------------------------------------------
    DATA_MASTER_SM_REG: process (Sys_Clk)
    begin
        if Sys_Clk'event and Sys_Clk = '1' then
            if Sys_Rst = '1' then
                data_master_cs        <= IDLE; 
                ld_next_data_master   <= '0';
                ld_second_data_master <= '0';
            else
                data_master_cs        <= data_master_ns;
                ld_next_data_master   <= ld_next_data_master_com;
                ld_second_data_master <= ld_second_data_master_com;
            end if;
        end if;
    end process DATA_MASTER_SM_REG;


    ---------------------------------------------------------------------------
    -- Data Master State Machine Combinational Process
    ---------------------------------------------------------------------------
    DATA_MASTER_SM_CMB: process (data_master_cs,
                                 data_arb_cycle_i,
                                 addr_arb_cycle_fe,
                                 data_arb_cycle_fe,
                                 null_arb_cycle)                                            
    begin
    
    data_master_ns            <= data_master_cs;
    addr_one_ahead_data       <= '0';
    addr_two_ahead_data       <= '0';
    ld_next_data_master_com   <= '0';
    ld_second_data_master_com <= '0';

    case data_master_cs is
    
        -------------------------- IDLE -----------------------------
        when IDLE =>    

            if (addr_arb_cycle_fe = '1' and data_arb_cycle_fe = '0' 
                                        and data_arb_cycle_i='0') then
                ld_next_data_master_com <= '1';
                data_master_ns <= ONE_AHEAD;
            end if;

        -------------------------- ONE_AHEAD ------------------------
        when ONE_AHEAD =>                
            
            addr_one_ahead_data <= '1';
            
            if data_arb_cycle_i = '1' or null_arb_cycle = '1' then
                --addr_one_ahead_data <= '0';
                data_master_ns <= IDLE;                
            else
                --addr_one_ahead_data <= '1';
                if (addr_arb_cycle_fe = '1' and data_arb_cycle_fe = '0' 
                                            and data_arb_cycle_i='0') then
                    ld_second_data_master_com <= '1';
                    data_master_ns <= TWO_AHEAD;
                end if;                    
            end if;

        -------------------------- TWO_AHEAD ------------------------
        when TWO_AHEAD =>    

            addr_one_ahead_data <= '1';
            addr_two_ahead_data <= '1';

            if data_arb_cycle_i = '1' then
                if addr_arb_cycle_fe = '0' then
                    data_master_ns <= ONE_AHEAD;               
                else
                    ld_second_data_master_com <= '1';
                end if; 
            end if;

        -------------------------- OTHERS ----------------------------    
        when others =>
            data_master_ns <= IDLE;

    end case;
            
    end process DATA_MASTER_SM_CMB;


    ---------------------------------------------------------------------------
    -- Determine the Address and Data Mux Selects
    --------------------------------------------------------------------------- 
    -- If only 1 MCH CS is supported, then can arbitrate early and let address
    -- mux switch before data mux. However, if there are multiple CS supported,
    -- then have to determine if the CS for the new transaction is the same as 
    -- the current CS before switching the address mux. If these are the same, 
    -- then its OK to switch the address mux. If they're not, then the address 
    -- mux can't switch until the data mux does.
    ONE_CS_MUX_SEL_GEN: if C_NUM_MCH_CS = 1 generate

        IPIC_Addr_Mux_Sel <= addr_master_i;
        
        IPIC_Data_Mux_Sel <= data_master_i;

    end generate ONE_CS_MUX_SEL_GEN;
    
    MULTI_CS_MUX_SEL_GEN: if C_NUM_MCH_CS > 1 generate
    -- Support of multiple CS will incur additional latency
    -- will use addr_arb_cycle to register whether the CSs are equal
    -- will use addr_arb_cycle_d1 to generate addr mux select
    signal addr_arb_cycle_d1  : std_logic;
    signal data_arb_cycle_d1  : std_logic;
    signal next_cs            : std_logic_vector(0 to C_NUM_MCH_CS-1);
    signal cs_equal           : std_logic;
    
    begin
    
        -----------------------------------------------------------------------
        -- ADDR_ARB_CYCLE_REG : Registering arbiter cycle singnal
        -----------------------------------------------------------------------
        ADDR_ARB_CYCLE_REG: process (Sys_Clk)
        begin
            if Sys_Clk'event and Sys_Clk = '1' then
                if Sys_Rst = '1' then
                    addr_arb_cycle_d1 <= '0';
                    data_arb_cycle_d1 <= '0';
                else
                    addr_arb_cycle_d1 <= addr_arb_cycle_i;
                    data_arb_cycle_d1 <= data_arb_cycle_i;
                end if;
            end if;
        end process ADDR_ARB_CYCLE_REG;
        
     
        -- determine next CS
        NEXT_CS_MUX_I: entity proc_common_v3_00_a.mux_onehot_f(imp)
            generic map (
                            C_DW     => C_NUM_MCH_CS,
                            C_NB     => C_NUM_MASTERS,
                            C_FAMILY => C_FAMILY
                         )
            port map (
                        D => CS_Bus,
                        S => grant_i,
                        Y => next_cs
                     );
        -----------------------------------------------------------------------
        -- CS_EQUAL_REG : compare the next CS to the current CS
        -----------------------------------------------------------------------
        CS_EQUAL_REG: process (Sys_Clk)
        begin
            if Sys_Clk'event and Sys_Clk = '1' then
                if Sys_Rst = '1' then
                    cs_equal <= '0';
                elsif addr_arb_cycle_i = '1' then
                    if next_cs = Bus2IP_CS(0 to C_NUM_MCH_CS-1) then
                        cs_equal <= '1';
                    else
                        cs_equal <= '0';
                    end if;
                end if;
            end if;
        end process CS_EQUAL_REG;
        
        -----------------------------------------------------------------------
        -- determine address mux select
        -- if addr_arb_cycle and data_arb_cycle, then addr_mux_select
        -- equals grants regardless of whether the CSs are equal are not
        -- then if the arb cycles aren't the same, then use addr_arb_cycle_d1
        -- and check cs_equal. If the CSs are not equal, the addr_mux_select
        -- should be the data master and if they are equal, the addr_mux_select
        -- can be the address master. If its not an addr_arb_cycle, then
        -- addr_mux_select = address master
        -----------------------------------------------------------------------
        ADDR_MUX_SELECT_PROCESS: process (addr_arb_cycle_d1,
                                          data_arb_cycle_d1,
                                          addr_master_i,
                                          data_master_i,
                                          cs_equal)
        begin
            if addr_arb_cycle_d1 = '1' then
                if data_arb_cycle_d1 = '1' then
                    IPIC_Addr_Mux_Sel <= addr_master_i;
                else 
                    if cs_equal = '1' then
                        IPIC_Addr_Mux_Sel <= addr_master_i;
                    else 
                        IPIC_Addr_Mux_Sel <= data_master_i;
                    end if;
                end if;
            else
                IPIC_Addr_Mux_Sel <= addr_master_i;
            end if;
        end process ADDR_MUX_SELECT_PROCESS;
        
        -- determine data mux select
        IPIC_Data_Mux_Sel <= data_master_i;
        
    end generate MULTI_CS_MUX_SEL_GEN;
                       
end generate FIXED_PRIORITY_GEN;

end imp;

