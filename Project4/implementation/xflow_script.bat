@ECHO OFF
@REM ###########################################
@REM # Script file to run the flow 
@REM # 
@REM ###########################################
@REM #
@REM # Command line for ngdbuild
@REM #
ngdbuild -p xc3s1600efg320-4 -nt timestamp -bm Project4.bmm "C:/Users/jfalb1/Desktop/implementation/Project4.ngc" -uc Project4.ucf Project4.ngd 

@REM #
@REM # Command line for map
@REM #
map -o Project4_map.ncd -pr b -ol high -timing -detail Project4.ngd Project4.pcf 

@REM #
@REM # Command line for par
@REM #
par -w -ol high Project4_map.ncd Project4.ncd Project4.pcf 

@REM #
@REM # Command line for post_par_trce
@REM #
trce -e 3 -xml Project4.twx Project4.ncd Project4.pcf 

