@echo off
call ../../../../../../../settings64_iverilog.bat

iverilog -g2012 -o system.vvp -c system.vc -s mpsoc_dbg_testbench -I ../../../../../../../rtl/pu/msp430/verilog/bb/pkg
vvp system.vvp
pause
