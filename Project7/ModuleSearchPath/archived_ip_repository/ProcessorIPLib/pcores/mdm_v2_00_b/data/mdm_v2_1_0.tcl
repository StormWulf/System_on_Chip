#***--------------------------------***------------------------------------***
#
#                        SYSLEVEL_DRC_PROC
#
#***--------------------------------***------------------------------------***

proc check_syslevel_settings { mhsinst } {

  set inst_name [xget_hw_parameter_value $mhsinst "INSTANCE"]
  set port_name Debug_SYS_Rst

  set error_str "To be able to reset the system from the debugger, connect the PORT $port_name in $inst_name to the PORT MB_Debug_SYS_Rst in proc_sys_reset"

  if {[check_connected_port $mhsinst $port_name] == 0 && [check_microblaze_present $mhsinst] == 1} {
    error $error_str "" "mdt_error"  
  }

}

proc check_connected_port { mhsinst port_name } {

  set connector [xget_hw_port_value $mhsinst $port_name]

  if {[llength $connector] == 0 || [xcheck_constant_signal $connector]} {
    return 0
  } else {
    return 1
  }

}

proc check_microblaze_present { mhsinst } {

  set mhs_handle [xget_hw_parent_handle $mhsinst]
  set mhsinst_list [xget_hw_ipinst_handle $mhs_handle *]
  
  foreach mhsinst $mhsinst_list {
    set mhsinst_type [xget_hw_value $mhsinst]
    if { $mhsinst_type == "microblaze" } {
	    return 1
    }
  }
  return 0

}


#***--------------------------------***------------------------------------***
#
#                   SAV PROC (XPS GUI IP instantiation)
#
#***--------------------------------***------------------------------------***

# Set a parameter value or add a parameter with a new value to an IP instance
proc set_or_add_parameter_value {mhsinst parameter value} {
   set param_handle [xget_hw_parameter_handle $mhsinst $parameter]
   if {[string length $param_handle] == 0} {
      xadd_hw_ipinst_parameter $mhsinst $parameter $value
   } else {
      xset_hw_parameter_value $param_handle $value
   }
}

# Check if actual family series is greater than or equal to a given series
proc series_greater_or_equal {mhsinst series} {
   if {[string length $mhsinst] == 0} {
      return 0
   }
   set ip_family [xget_hw_parameter_value $mhsinst "C_FAMILY"]
   if {[string length $ip_family] == 0} {
      return 0
   }
   if {[regexp {[A-Za-z]*([0-9]*)[A-Za-z]*} $ip_family match number] == 0} {
      return 0
   }
   return [expr $number >= $series]
}

# Automatically called by XPS when MDM is instantiated
proc xps_sav_add_new_mhsinst {mergedmhs mhsinst mpd} {

   # Set AXI interconnect in MHS for series >= "7"
   set paramvallist {{"C_INTERCONNECT" 2 }}
   set mergedmhsinst [xget_hw_ipinst_handle $mergedmhs [xget_hw_name $mhsinst]]

   foreach paramval $paramvallist {
      if {[series_greater_or_equal $mergedmhsinst "7"]} {
         set_or_add_parameter_value $mhsinst [lindex $paramval 0] [lindex $paramval 1]
      }
   }
}
