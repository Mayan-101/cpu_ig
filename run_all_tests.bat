@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo       RISC CPU Pipeline Integration - FULL Test Suite
echo ============================================================

:: Define core source files (excluding testbenches)
set ALU_CORE=ALU/alu_top.v ALU/alu_int.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v ALU/sub_32bit.v ALU/bitwise_unit.v ALU/barrel_shifter.v ALU/comparator_unit.v ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/divider.v ALU/float_add_sub.v ALU/float_mul.v ALU/float_norm.v ALU/float_unpacker.v ALU/float_packer.v ALU/mantissa_aligner.v
set PIPE_CORE=Pipeline/cpu_top.v Pipeline/pc_reg.v Pipeline/pipeline_reg.v Pipeline/control_unit.v Pipeline/imm_extender.v Pipeline/hazard_detection_unit.v Pipeline/forwarding_unit.v Pipeline/branch_hazard_handler.v Pipeline/branch_target_calc.v
set REG_CORE=RegisterFile/register_file.v RegisterFile/reg_bank8.v RegisterFile/reg32.v
set MEM_CORE=Memory/address_decoder.v Memory/ram.v Memory/rom.v Memory/rom_async_dp.v Memory/ram_async.v Memory/l1_cache.v Memory/addr_decomp.v Memory/cache_sram_way.v

echo.
echo [SECTION 1/3] COMPONENT-LEVEL TESTS
echo ------------------------------------------------------------

echo [1.1] Testing Register File...
iverilog -o test_rf.vvp RegisterFile/tb_register_file.v %REG_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_rf.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo [1.2] Testing RAM (Synchronous)...
iverilog -o test_ram.vvp Memory/tb_ram.v Memory/ram.v
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_ram.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo [1.3] Testing Address Decoder...
iverilog -o test_dec.vvp Memory/tb_address_decoder.v Memory/address_decoder.v
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_dec.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo [1.4] Testing ALU Top-Level...
iverilog -o test_alu.vvp ALU/tb_alu_top.v %ALU_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_alu.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo.
echo [SECTION 2/3] PIPELINE TESTS
echo ------------------------------------------------------------

echo [2.1] Testing Full Pipeline (CPU Top)...
iverilog -o test_pipe.vvp Pipeline/tb_cpu_top.v %PIPE_CORE% %ALU_CORE% %REG_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_pipe.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo [2.2] Testing .1 (Sequential ALU Integration)...
iverilog -o test_cpu_core.vvp Pipeline/tb_cpu_core.v %PIPE_CORE% %ALU_CORE% %REG_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_cpu_core.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo.
echo [SECTION 3/3] SYSTEM INTEGRATION TESTS
echo ------------------------------------------------------------

echo [3.1] Testing .2 (System + Memory)...
:: Create ROM for .2
(
echo 68100001
echo 682cafeb
echo 4c208abe
echo 84204000
echo 80504000
echo 84200000
echo 80600000
echo fc000000
) > rom_init.mem
iverilog -o test_cpu_core_mem.vvp tb_cpu_core_mem.v system_top.v %MEM_CORE% %PIPE_CORE% %ALU_CORE% %REG_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_cpu_core_mem.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo [3.2] Testing .3 (System + Cache)...
:: Create ROM for .3
(
echo 40101000
echo 40200008
echo 80304000
echo 44208001
echo C4203FFD
echo FC000000
) > rom_init.mem
iverilog -o test_cpu_core_cache.vvp tb_cpu_core_cache.v system_cache_top.v %MEM_CORE% %PIPE_CORE% %ALU_CORE% %REG_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_cpu_core_cache.vvp | findstr /V "Time="
if %errorlevel% neq 0 (echo Execution Failed! && exit /b 1)

echo.
echo ============================================================
echo              ALL TESTS PASSED SUCCESSFULLY!
echo ============================================================
del *.vvp
pause
