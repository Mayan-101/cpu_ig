@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: run_cycle_trace.bat  —  Build and run the T-state tracer
::
:: Usage:
::   Scripts\run_cycle_trace.bat <program_name>
:: Example:
::   Scripts\run_cycle_trace.bat test_rv32i_alu
::
:: Outputs saved to Traces/ directory
:: ============================================================

cd /d "%~dp0.."

set "PROG=%~1"
if "%PROG%"=="" (
    echo [ERROR] Supply a program name as the first argument.
    echo Example: Scripts\run_cycle_trace.bat test_rv32i_alu
    exit /b 1
)

if not exist "Programs\%PROG%.asm" (
    echo [ERROR] Program file not found: Programs\%PROG%.asm
    exit /b 1
)

if not exist "Traces" mkdir Traces

set "LIBS=-y ALU -y Memory -y Pipeline -y RegisterFile -y Peripherals -y System_Testbenchs"
set "INCS=-I opcode -I ALU -I Memory -I Pipeline -I RegisterFile -I Peripherals -I System_Testbenchs"

echo.
echo [1/4] Assembling %PROG%.asm...
python Assembler/assembler.py Programs/%PROG%.asm Programs/%PROG%.hex
if %errorlevel% neq 0 exit /b 1
echo       OK

echo [2/4] Compiling tracer...
iverilog -g2012 -o sim_trace.out %INCS% %LIBS% Testbenchs/tb_cycle_tracer.v
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed.
    exit /b 1
)
echo       OK

echo [3/4] Running simulation: %PROG%
vvp sim_trace.out +PROG=Programs/%PROG%.hex > Traces/%PROG%_trace.txt 2>&1
echo       Done — saved to Traces/%PROG%_trace.txt

echo.
type Traces\%PROG%_trace.txt

:: Attempt Python plot
where python >nul 2>nul
if %errorlevel% equ 0 (
    echo.
    echo [4/4] Generating cycle chart...
    python Assembler/plot_cycles.py Traces/%PROG%_trace.txt --save --outdir Traces
    
    :: Rename files to have the program prefix
    if exist Traces\waterfall.png move /y Traces\waterfall.png Traces\%PROG%_waterfall.png >nul
    if exist Traces\cycle_report.png move /y Traces\cycle_report.png Traces\%PROG%_cycle_report.png >nul
) else (
    echo [4/4] Python not found — skipping chart generation.
)

if exist sim_trace.out del sim_trace.out
echo.
echo Done.
endlocal
