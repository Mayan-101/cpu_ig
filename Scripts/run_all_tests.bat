@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo       RISC CPU Pipeline Integration - FULL Test Suite
echo ============================================================

:: Define core source files (excluding testbenches)
set ALU_CORE=ALU/alu_top.v ALU/alu_int.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v ALU/sub_32bit.v ALU/bitwise_unit.v ALU/barrel_shifter.v ALU/comparator_unit.v ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/divider.v ALU/float_add_sub.v ALU/float_mul.v ALU/float_norm.v ALU/float_unpacker.v ALU/float_packer.v ALU/mantissa_aligner.v
set PIPE_CORE=Pipeline/cpu_top.v Pipeline/pc_reg.v Pipeline/pipeline_reg.v Pipeline/control_unit.v Pipeline/imm_extender.v Pipeline/hazard_detection_unit.v Pipeline/forwarding_unit.v Pipeline/branch_hazard_handler.v Pipeline/branch_target_calc.v
set REG_CORE=RegisterFile/register_file.v RegisterFile/reg32.v
set MEM_CORE=Memory/address_decoder.v Memory/ram.v Memory/rom.v Memory/rom_async_dp.v Memory/ram_async.v Memory/l1_cache.v Memory/addr_decomp.v Memory/cache_sram_way.v
set PERI_CORE=Peripherals/io_peripheral_bus.v Peripherals/gpio.v Peripherals/timer.v Peripherals/uart.v Peripherals/interrupt_controller.v

echo.
echo [SECTION 1] ALU COMPONENT TESTS
echo ------------------------------------------------------------
call :run_test 1.01 "Half Adder"          Tests/tb_half_adder.v           "ALU/half_adder.v"
call :run_test 1.02 "Full Adder"          Tests/tb_full_adder.v           "ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.03 "CLA 4-bit"           Tests/tb_cla4bit.v              "ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.04 "CLA 16-bit"          Tests/tb_cla_16bit.v            "ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.05 "CLA 32-bit"          Tests/tb_cla_32bit.v            "ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.06 "Subtractor 32-bit"   Tests/tb_sub_32bit.v            "ALU/sub_32bit.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.07 "Bitwise Unit"        Tests/tb_bitwise_unit.v         "ALU/bitwise_unit.v"
call :run_test 1.08 "Barrel Shifter"      Tests/tb_barrel_shifter.v       "ALU/barrel_shifter.v"
call :run_test 1.09 "Comparator Unit"     Tests/tb_comparator_unit.v      "ALU/comparator_unit.v"
call :run_test 1.10 "Booth Encoder"       Tests/tb_booth_encoder.v        "ALU/booth_encoder.v"
call :run_test 1.11 "Booth Multiplier"    Tests/tb_booth_multiplier.v     "ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.12 "Divider"             Tests/tb_divider.v              "ALU/divider.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.13 "Mantissa Aligner"    Tests/tb_mantissa_aligner.v     "ALU/mantissa_aligner.v"
call :run_test 1.14 "Float Normalizer"    Tests/tb_float_norm.v           "ALU/float_norm.v"
call :run_test 1.15 "Float Add/Sub"       Tests/tb_float_add_sub.v        "ALU/float_add_sub.v ALU/float_unpacker.v ALU/float_packer.v ALU/mantissa_aligner.v ALU/float_norm.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v"
call :run_test 1.16 "Float Multiplier"    Tests/tb_float_mul.v            "ALU/float_mul.v ALU/float_unpacker.v ALU/float_packer.v ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v ALU/float_norm.v"
call :run_test 1.17 "Float Codec"         Tests/tb_float_codec.v          "ALU/float_unpacker.v ALU/float_packer.v"
call :run_test 1.18 "ALU Integer Core"    Tests/tb_alu_int.v              "ALU/alu_int.v %ALU_BASIC%"
call :run_test 1.19 "ALU Top-Level"       Tests/tb_alu_top.v              "%ALU_CORE%"

echo.
echo [SECTION 2] REGISTER FILE TESTS
echo ------------------------------------------------------------
call :run_test 2.01 "32-bit Register"     Tests/tb_reg32.v                "RegisterFile/reg32.v"
call :run_test 2.02 "8-Reg Bank"          Tests/tb_reg_bank8.v            "RegisterFile/reg_bank8.v RegisterFile/reg32.v"
call :run_test 2.03 "Full Register File"  Tests/tb_register_file.v        "%REG_CORE%"

echo.
echo [SECTION 3] PIPELINE LOGIC TESTS
echo ------------------------------------------------------------
call :run_test 3.01 "PC Register"         Tests/tb_pc_reg.v               "Pipeline/pc_reg.v"
call :run_test 3.02 "Pipeline Register"   Tests/tb_pipeline_reg.v         "Pipeline/pipeline_reg.v"
call :run_test 3.03 "Imm Extender"        Tests/tb_imm_extender.v         "Pipeline/imm_extender.v"
call :run_test 3.04 "Branch Target Calc"  Tests/tb_branch_target_calc.v   "Pipeline/branch_target_calc.v"
call :run_test 3.05 "Control Unit"        Tests/tb_control_unit.v         "Pipeline/control_unit.v"
call :run_test 3.06 "Forwarding Unit"     Tests/tb_forwarding_unit.v      "Pipeline/forwarding_unit.v"
call :run_test 3.07 "Hazard Detection"    Tests/tb_hazard_detection_unit.v "Pipeline/hazard_detection_unit.v"
call :run_test 3.08 "Branch Hazard Hdlr"  Tests/tb_branch_hazard_handler.v "Pipeline/branch_hazard_handler.v"

echo.
echo [SECTION 4] PIPELINE STAGE TESTS
echo ------------------------------------------------------------
call :run_test 4.01 "IF Stage"            Tests/tb_if_stage.v             "Pipeline/if_stage.v Pipeline/pc_reg.v Memory/rom.v Memory/rom_async_dp.v"
call :run_test 4.02 "ID Stage"            Tests/tb_id_stage.v             "Pipeline/id_stage.v Pipeline/control_unit.v Pipeline/imm_extender.v %REG_CORE%"
call :run_test 4.03 "EX Stage"            Tests/tb_ex_stage.v             "Pipeline/ex_stage.v %ALU_CORE% Pipeline/branch_target_calc.v"
call :run_test 4.04 "MEM Stage"           Tests/tb_mem_stage.v            "Pipeline/mem_stage.v Memory/ram_async.v"
call :run_test 4.05 "WB Stage"            Tests/tb_wb_stage.v             "Pipeline/wb_stage.v"

echo.
echo [SECTION 5] MEMORY ^& CACHE TESTS
echo ------------------------------------------------------------
call :run_test 5.01 "ROM Core"            Tests/tb_rom.v                  "Memory/rom.v Memory/rom_async_dp.v Memory/rom_async.v"
call :run_test 5.02 "RAM Core"            Tests/tb_ram.v                  "Memory/ram.v"
call :run_test 5.03 "Address Decoder"     Tests/tb_address_decoder.v      "Memory/address_decoder.v"
call :run_test 5.04 "Addr Decomposer"     Tests/tb_addr_decomp.v          "Memory/addr_decomp.v"
call :run_test 5.05 "Cache SRAM Way"      Tests/tb_cache_sram_way.v       "Memory/cache_sram_way.v"
call :run_test 5.06 "LRU Unit"            Tests/tb_lru_unit.v             "Memory/lru_unit.v"
call :run_test 5.07 "Write-Thru Ctrl"     Tests/tb_wt_controller.v        "Memory/wt_controller.v"
call :run_test 5.08 "L1 Cache"            Tests/tb_l1_cache.v             "Memory/l1_cache.v Memory/addr_decomp.v Memory/cache_sram_way.v"
call :run_test 5.09 "Cache Core 4-Way"    Tests/tb_cache_core_4way.v      "Memory/cache_core_4way.v Memory/addr_decomp.v Memory/cache_sram_way.v Memory/lru_unit.v"
call :run_test 5.10 "Bus Arbiter"         Tests/tb_bus_arbiter.v          "Memory/bus_arbiter.v"
call :run_test 5.11 "L2 I-Cache"          Tests/tb_l2_icache.v            "Memory/l2_icache.v Memory/cache_core_4way.v Memory/addr_decomp.v Memory/cache_sram_way.v Memory/lru_unit.v"
call :run_test 5.12 "L2 D-Cache"          Tests/tb_l2_dcache.v            "Memory/l2_dcache.v Memory/cache_core_4way.v Memory/addr_decomp.v Memory/cache_sram_way.v Memory/lru_unit.v Memory/wt_controller.v"
call :run_test 5.13 "Cache Hierarchy"     Tests/tb_cache_hierarchy.v      "Memory/cache_hierarchy.v Memory/l1_cache.v Memory/l2_icache.v Memory/l2_dcache.v Memory/cache_core_4way.v Memory/addr_decomp.v Memory/cache_sram_way.v Memory/lru_unit.v Memory/wt_controller.v"
call :run_test 5.14 "Cache Subsystem"     Tests/tb_cache_subsystem.v      "%MEM_CACHE% Memory/addr_decomp.v"

echo.
echo [SECTION 6] SYSTEM INTEGRATION TESTS
echo ------------------------------------------------------------
call :run_test 6.01 "CPU Core"            Tests/tb_cpu_core.v             "%PIPE_CORE% %ALU_CORE% %REG_CORE%"
call :run_test 6.02 "Peripherals Bus"     Tests/tb_peripherals.v          "%PERI_CORE% SystemTests/system_top.v %PIPE_CORE% %ALU_CORE% %REG_CORE% %MEM_BASIC%"
call :run_test 6.03 "Full System (Top)"   Tests/tb_cpu_top.v              "%PIPE_CORE% %ALU_CORE% %REG_CORE% %MEM_CORE% %PERI_CORE%"

echo.
echo ============================================================
echo                TEST SUMMARY
echo ============================================================
echo Total Passed: %PASS_COUNT%
echo Total Failed: %FAIL_COUNT%
echo ============================================================

if %FAIL_COUNT% equ 0 (
    echo [RESULT] ALL TESTS PASSED SUCCESSFULLY!
) else (
    echo [RESULT] SOME TESTS FAILED. CHECK LOGS.
)

:: pause
exit /b 0

:: ------------------------------------------------------------
:: Helper Function: run_test
:: ------------------------------------------------------------
:run_test
set TEST_ID=%1
set TEST_NAME=%~2
set TEST_TB=%3
set DEPS=%~4

echo [%TEST_ID%] Testing %TEST_NAME%...
iverilog -I opcode -o temp_test.vvp %TEST_TB% %DEPS%
if %errorlevel% neq 0 (
    echo   [COMPILE FAIL] %TEST_NAME%
    set /a FAIL_COUNT+=1
    exit /b
)

vvp temp_test.vvp | findstr /V "Time=" > last_out.txt
if %errorlevel% neq 0 (
    echo   [EXEC FAIL] %TEST_NAME%
    set /a FAIL_COUNT+=1
    del temp_test.vvp
    exit /b
)

echo   [PASS] %TEST_NAME%
set /a PASS_COUNT+=1
del temp_test.vvp
exit /b
