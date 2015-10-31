@ECHO OFF
@REM ###########################################
@REM # Script file to run the flow 
@REM # 
@REM ###########################################
@REM #
@REM # Command line for ngdbuild
@REM #
ngdbuild -p xc3s1600efg320-4 -nt timestamp -bm Project5.bmm "E:/SoC/Project5/implementation/Project5.ngc" -uc Project5.ucf Project5.ngd 

@REM #
@REM # Command line for map
@REM #
map -o Project5_map.ncd -pr b -ol high -timing -detail Project5.ngd Project5.pcf 

