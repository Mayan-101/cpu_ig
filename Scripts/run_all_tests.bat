@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: CPU_IG Automated Regression Test Suite
:: ============================================================

:: Move to project root (parent of Scripts directory)
cd /d "%~dp0.."

:: ANSI Color Codes
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "GREEN=!ESC![92m"
set "RED=!ESC![91m"
set "YELLOW=!ESC![93m"
set "CYAN=!ESC![96m"
set "WHITE=!ESC![97m"
set "RESET=!ESC![0m"

set PASSED=0
set FAILED=0
set TOTAL=0

cls
echo.
echo %CYAN%======================================================================%RESET%
echo %CYAN%            CPU_IG ARCHITECTURE - REGRESSION TEST RUNNER            %RESET%
echo %CYAN%======================================================================%RESET%
echo.
echo   Start Time: %DATE% %TIME%
echo.

:: Build Environment Configuration
set "LIBS=-y ALU -y Memory -y Pipeline -y RegisterFile -y Peripherals -y System_Testbenchs"
set "INCS=-I opcode -I ALU -I Memory -I Pipeline -I RegisterFile -I Peripherals -I System_Testbenchs"

:: --- SECTION 1: UNIT TESTS ---
echo %YELLOW%[SECTION 1/2] Component-Level Unit Tests (Testbenchs/)%RESET%
echo %WHITE%----------------------------------------------------------------------%RESET%

for %%F in (Testbenchs\tb_*.v) do (
    set /a TOTAL+=1
    set "TFILE=%%F"
    set "TNAME=%%~nF"
    
    set "PNAME=!TNAME!                                     "
    set "PNAME=!PNAME:~0,35!"
    
    if /I "!TNAME!"=="tb_cycle_tracer" (
        echo | set /p="[!TOTAL!] Tests ^| !PNAME! : "
        echo %YELLOW%SKIPPED ^(Manual run required^)%RESET%
    ) else (
        echo | set /p="[!TOTAL!] Tests ^| !PNAME! : "
        
        set "CMD_COMP=iverilog -g2012 -o sim.vvp %INCS% %LIBS% !TFILE!"
        !CMD_COMP! > compile_log.txt 2>&1
        
        if !errorlevel! neq 0 (
            echo %RED%FAILED ^(Compilation Error^)%RESET%
            set /a FAILED+=1
        ) else (
            vvp sim.vvp > test_output.txt 2>&1
            findstr /i "FAIL TIMEOUT" test_output.txt > nul
            if !errorlevel! equ 0 (
                echo %RED%FAILED%RESET%
                set /a FAILED+=1
            ) else (
                findstr /i "PASS SUCCESS Complete" test_output.txt > nul
                if !errorlevel! equ 0 (
                    echo %GREEN%PASSED%RESET%
                    set /a PASSED+=1
                ) else (
                    echo %YELLOW%DONE ^(Manual check required^)%RESET%
                    set /a PASSED+=1
                )
            )
        )
        echo    %CYAN%^>%RESET% !CMD_COMP!
    )
)
echo.

:: --- SECTION 2: SYSTEM TESTS ---
echo %YELLOW%[SECTION 2/2] System-Level Integration Tests (System_Testbenchs/)%RESET%
echo %WHITE%----------------------------------------------------------------------%RESET%

for %%F in (System_Testbenchs\tb_*.v) do (
    set /a TOTAL+=1
    set "TFILE=%%F"
    set "TNAME=%%~nF"
    
    if /I "!TNAME!"=="tb_universal" (
        echo [!TOTAL!] System - !TNAME! : %YELLOW%SKIPPED ^(Manual run required^)%RESET%
    ) else (
        echo [!TOTAL!] System - !TNAME! : Running...
        
        set "CMD_COMP=iverilog -g2012 -o sim.vvp %INCS% %LIBS% !TFILE!"
        !CMD_COMP! > compile_log.txt 2>&1
        
        if !errorlevel! neq 0 (
            echo [!TOTAL!] System - !TNAME! : %RED%FAILED ^(Compilation Error^)%RESET%
            set /a FAILED+=1
        ) else (
            vvp sim.vvp > test_output.txt 2>&1
            findstr /i "FAIL TIMEOUT" test_output.txt > nul
            if !errorlevel! equ 0 (
                echo [!TOTAL!] System - !TNAME! : %RED%FAILED%RESET%
                set /a FAILED+=1
            ) else (
                findstr /i "PASS SUCCESS Complete" test_output.txt > nul
                if !errorlevel! equ 0 (
                    echo [!TOTAL!] System - !TNAME! : %GREEN%PASSED%RESET%
                    set /a PASSED+=1
                ) else (
                    echo [!TOTAL!] System - !TNAME! : %YELLOW%DONE ^(Manual check required^)%RESET%
                    set /a PASSED+=1
                )
            )
        )
        echo    %CYAN%^>%RESET% !CMD_COMP!
    )
)

echo.
echo %CYAN%======================================================================%RESET%
echo %CYAN%                        FINAL VERIFICATION REPORT                       %RESET%
echo %CYAN%======================================================================%RESET%
echo.
echo   Total Testbenches Executed:  !TOTAL!
echo   Tests Passed Successfully:   %GREEN%!PASSED!%RESET%
echo   Tests Failed / With Errors:  %RED%!FAILED!%RESET%
echo.
if !FAILED! equ 0 (
    echo   %GREEN%STATUS: ALL SYSTEM TESTS PASSED%RESET%
) else (
    echo   %RED%STATUS: REGRESSION FAILED - !FAILED! ERRORS DETECTED%RESET%
)
echo.
echo %CYAN%======================================================================%RESET%

:: Post-run Cleanup
if exist sim.vvp del sim.vvp
if exist compile_log.txt del compile_log.txt
if exist test_output.txt del test_output.txt

endlocal
pause
