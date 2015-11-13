###############################################################################
## DISCLAIMER OF LIABILITY
##
## This file contains proprietary and confidential information of
## Xilinx, Inc. ("Xilinx"), that is distributed under a license
## from Xilinx, and may be used, copied and/or disclosed only
## pursuant to the terms of a valid license agreement with Xilinx.
##
## XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
## ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
## EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
## LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
## MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
## does not warrant that functions included in the Materials will
## meet the requirements of Licensee, or that the operation of the
## Materials will be uninterrupted or error-free, or that defects
## in the Materials will be corrected. Furthermore, Xilinx does
## not warrant or make any representations regarding use, or the
## results of the use, of the Materials in terms of correctness,
## accuracy, reliability or otherwise.
##
## Xilinx products are not designed or intended to be fail-safe,
## or for use in any application requiring fail-safe performance,
## such as life-support or safety devices or systems, Class III
## medical devices, nuclear facilities, applications related to
## the deployment of airbags, or any other applications that could
## lead to death, personal injury or severe property or
## environmental damage (individually and collectively, "critical
## applications"). Customer assumes the sole risk and liability
## of any use of Xilinx products in critical applications,
## subject only to applicable laws and regulations governing
## limitations on product liability.
##
## Copyright 2007, 2009 Xilinx, Inc.
## All rights reserved.
##
## This disclaimer and copyright notice must be retained as part
## of this file at all times.
##
###############################################################################
##
###############################################################################
##   This disclaimer and copyright notice must be retained as part	
##   of this file at all times.						
##  									
##   emc_common_v2_1_0.tcl						
##									
###############################################################################
#
# check address range
# if C_DEV_MIR_ENABLE = 1 then C_HIGHADDR - C_BASEADDR >= 0x144
#
# @param   mhsinst    the mhs instance handle
#
proc check_addr_range {mhsinst} {

    set base_param "C_BASEADDR"
    set high_param "C_HIGHADDR"

    set base_addr [xget_hw_parameter_value $mhsinst $base_param]
    set high_addr [xget_hw_parameter_value $mhsinst $high_param]

    # convert to hexadecimal format
    set base_addr [xformat_addr_string $base_addr $base_param]
    set high_addr [xformat_addr_string $high_addr $high_param]

    if {[compare_unsigned_addr_strings $base_addr $base_param $high_addr $high_param] == 1} {

        return

    }

    set range [expr $high_addr - $base_addr]

    if {[xget_hw_parameter_value $mhsinst "C_DEV_MIR_ENABLE"]} {

        # addr_range >= 0x144
        if {$range < [format %d "0x144"]} {

	    set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "Invalid address range for $instname:\naddress range specified by $base_param and $high_param must be larger than or equal to 0x144 when C_DEV_MIR_ENABLE = 1" "" "mdt_error"
        }
    }          
}


#
# check C_MAX_MEM_WIDTH
# C_MAX_MEM_WIDTH = max(C_MEMx_WIDTH)
#
# @param   mhsinst    the mhs instance handle
#
proc check_max_mem_width { mhsinst  } {

    set max_mem_width [xget_hw_parameter_value $mhsinst "C_MAX_MEM_WIDTH"]
    set num_banks     [xget_hw_parameter_value $mhsinst "C_NUM_BANKS_MEM"]
    set max "0"

    for {set i 0} {$i < $num_banks} {incr i} {

        set bank_param [concat C_MEM${i}_WIDTH] 
        set bank_value [xget_hw_parameter_value $mhsinst $bank_param ]

        if {$bank_value > $max} {

            set max $bank_value
        }
    }

    if {$max_mem_width != $max} {

	set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "Invalid $instname parameter:\nC_MAX_MEM_WIDTH must be the maximum value among width of memory bank data bus" "" "mdt_error"
 
    }

}

