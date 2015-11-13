@ECHO OFF
@REM ###########################################
@REM # Script file to run the flow 
@REM # 
@REM ###########################################
@REM #
@REM # Command line for ngdbuild
@REM #
ngdbuild -p xc3s1600efg320-4 -nt timestamp -bm Project5.bmm "C:/Users/wputn1/Desktop/Project6/implementation/Project5.ngc" -uc Project5.ucf Project5.ngd 

@REM #
@REM # Command line for map
@REM #
map -o Project5_map.ncd -pr b -ol high -timing -detail Project5.ngd Project5.pcf 

@REM #
@REM # Command line for par
@REM #
par -w -ol high Project5_map.ncd Project5.ncd Project5.pcf 

@REM #
@REM # Command line for post_par_trce
@REM #
trce -e 3 -xml Project5.twx Project5.ncd Project5.pcf 

