@echo off
set REG_CORE=RegisterFile/register_file.v RegisterFile/reg32.v

echo Running Register File Tests...
iverilog -o test_rf.vvp Tests/tb_register_file.v %REG_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_rf.vvp
del test_rf.vvp
pause
