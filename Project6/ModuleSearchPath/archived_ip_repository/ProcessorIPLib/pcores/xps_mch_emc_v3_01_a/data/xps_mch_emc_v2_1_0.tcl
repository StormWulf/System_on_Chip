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
##  									
##   xps_mch_emc_v2_1_0.tcl						
##									
###############################################################################
#
#***--------------------------------***------------------------------------***
#
#                            IPLEVEL_DRC_PROC
#
#***--------------------------------***------------------------------------***

#
# check C_MAX_MEM_WIDTH
# C_MAX_MEM_WIDTH = max(C_MEMx_WIDTH)
#
proc check_iplevel_settings {mhsinst} {

    xload_hw_library emc_common_v4_01_a

    hw_emc_common_v4_01_a::check_max_mem_width $mhsinst
    check_native_dwidth_and_num_channels  $mhsinst
    check_native_dwidth_and_splb_dwidth  $mhsinst
    check_dwidth_matching_and_num_channels $mhsinst
    check_flash_and_assync_type $mhsinst
	
}

#
# check C_NUM_CHANNELS and C_MCH_NATIVE_DWIDTH =64 only 
# if C_NUM_CHANNELS = 0
#
# @param   mhsinst    the mhs instance handle
#
proc check_native_dwidth_and_num_channels { mhsinst  } {

    set num_channels [xget_hw_parameter_value $mhsinst "C_NUM_CHANNELS"]
    set native_dwidth [xget_hw_parameter_value $mhsinst "C_MCH_NATIVE_DWIDTH"]

    if {$native_dwidth == 64} {
    	
    	if {$num_channels != 0} {

		set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        	error "Invalid $instname parameter:\C_MCH_NATIVE_DWIDTH can be 64 only when C_NUM_CHANNELS is 0" "" "mdt_error"
 	}
    }

}

# check C_SPLB_DWIDTH and C_MCH_NATIVE_DWIDTH
# C_SPLB_DWIDTH >=C_MCH_NATIVE_DWIDTH
#
# @param   mhsinst    the mhs instance handle
#
proc check_native_dwidth_and_splb_dwidth { mhsinst  } {

    set splb_dwidth [xget_hw_parameter_value $mhsinst "C_SPLB_DWIDTH"]
    set native_dwidth [xget_hw_parameter_value $mhsinst "C_MCH_NATIVE_DWIDTH"]

    if {$native_dwidth > $splb_dwidth} {
    	
	set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
       	error "Invalid $instname parameter:\C_MCH_NATIVE_DWIDTH should be less than or equal to C_SPLB_DWIDTH" "" "mdt_error"
    }

}

# check C_SYNCH_MEM_x and C_PAGEMODE_FLASH_x
# if C_PAGEMODE_FLASH_x = 1 only when C_SYNCH_MEM_x = 0
#
# @param   mhsinst    the mhs instance handle
#
proc check_flash_and_assync_type { mhsinst  } {

    set num_banks [xget_hw_parameter_value $mhsinst "C_NUM_BANKS_MEM"]

    for {set x 0} {$x < $num_banks} {incr x 1} {
        set bank_dwm [concat C_PAGEMODE_FLASH_${x}]
        set page_mode_en [xget_hw_parameter_value $mhsinst $bank_dwm]
        set bank_mem_type [concat C_SYNCH_MEM_x${x}]
        set mem_type [xget_hw_parameter_value $mhsinst $bank_mem_type]
        if {$page_mode_en == 1} {
            if {$mem_type == 1} {
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
		error "Invalid $instname parameter:C_PAGEMODE_FLASH_${x},  C_PAGEMODE_FLASH_${x} = 1 only if  C_SYNCH_MEM_${x} = 0(Async Memory)" "" "mdt_error"
            }
        }
    }
}


#
# check C_INCLUDE_DATAWIDTH_MATCHING_x, C_MEMx_WIDTH and C_MCH_NATIVE_DWIDTH
# C_INCLUDE_DATAWIDTH_MATCHING_x = 0 if and only if C_MCH_NATIVE_DWIDTH = C_MEMx_WIDTH
#
# @param   mhsinst    the mhs instance handle
#
proc check_dwidth_matching_and_num_channels { mhsinst  } {

    set num_banks [xget_hw_parameter_value $mhsinst "C_NUM_BANKS_MEM"]
    set native_dwidth [xget_hw_parameter_value $mhsinst "C_MCH_NATIVE_DWIDTH"]

    for {set x 0} {$x < $num_banks} {incr x 1} {
        set bank_dwm [concat C_INCLUDE_DATAWIDTH_MATCHING_${x}]
        set datawidth_matching [xget_hw_parameter_value $mhsinst $bank_dwm]
        set bank_width [concat C_MEM${x}_WIDTH]
        set mem_width [xget_hw_parameter_value $mhsinst $bank_width]
        if {$datawidth_matching == 0} {
            if {$native_dwidth != $mem_width} {
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
		error "Invalid $instname parameter:$bank_dwm,  $bank_dwm = 0 only if $bank_width = C_MCH_NATIVE_DWIDTH" "" "mdt_error"

            }
        }
    }
}


proc syslevel_update_mch_protocol { param_handle  } {

    set emcinst   	[xget_hw_parent_handle $param_handle]
    set param_name 	[xget_hw_name $param_handle]
    set x          	[string index $param_name 5]
    set mhs_handle 	[xget_hw_parent_handle $emcinst]
    set num_channels    [xget_hw_parameter_value $emcinst "C_NUM_CHANNELS"]
    set xcl_writexfer   [xget_hw_parameter_value $emcinst "C_XCL${x}_WRITEXFER"]
    if {$x < $num_channels} {
            set connector [xget_hw_busif_value $emcinst "MCH$x"]
            set busifs [xget_hw_connected_busifs_handle $mhs_handle $connector "initiator"]
            if {[string length $busifs] != 0} {
                set busif_parent [xget_hw_parent_handle $busifs]
                set iptype       [xget_hw_option_value  $busif_parent "IPTYPE"]
    		if {[string match -nocase *ixcl* ${connector}]} {
                   set interface [xget_hw_parameter_value $busif_parent "C_ICACHE_INTERFACE"]
                   if {[info exists interface] == 1 && $interface == 1} {
                       if {$xcl_writexfer == 1} {
			error "Invalid $emcinst parameter:\For XCL2 mode, C_XCL${x}_WRITEXFER should be 0 or 2" "" "mdt_error"
                      }
                       return "1"
                       
                   } else {
                       return "0"
                   }
    	    } elseif {[string match -nocase *dxcl* ${connector}]} {
                   set interface [xget_hw_parameter_value $busif_parent "C_DCACHE_INTERFACE"]
                   if {[info exists interface] == 1 && $interface == 1} {
                       if {$xcl_writexfer != 2} {
			error "Invalid $emcinst parameter:\For Dcache line in XCL2 mode, C_XCL${x}_WRITEXFER should always be set to 2" "" "mdt_error"
                       }
                       return "1"
                   } else {
                       return "0"
                   }
    	     } 
          } else {
                  return "0"
                   }
    } else {
    	return "0"
    }
}
