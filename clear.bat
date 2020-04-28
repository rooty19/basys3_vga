@echo off 
del /F /Q *.jou *.log
rd /S /Q .Xil basys3_vga
mkdir basys3_vga
set /p sel="relaunch project? (y/n) :"
if /i {%sel%}=={y} (vivado.bat -mode tcl -source basys3_vga.tcl & exit)
