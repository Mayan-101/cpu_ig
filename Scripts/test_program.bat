@echo off
if "%~1"=="" (
    echo Usage: test_universal.bat ^<program_name^> [dump_start] [dump_end] [float_mode]
    echo Example: .\Scripts\test_universal.bat float_sub 50 55 1
    exit /b 1
)

set PROG=%~1
set START=%~2
if "%START%"=="" set START=0
set END=%~3
if "%END%"=="" set END=127
set FLOAT=%~4
if "%FLOAT%"=="" set FLOAT=0

echo [1/3] Assembling %PROG%.asm...
python Assembler/assembler.py Programs/%PROG%.asm Programs/%PROG%.mem
if %errorlevel% neq 0 exit /b 1

echo [2/3] Compiling Universal Testbench...
iverilog -g2012 -o universal_sim.vvp -I opcode SystemTests/tb_universal.v SystemTests/system_cache_top.v ^
    ALU/alu_top.v ALU/alu_int.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ^
    ALU/full_adder.v ALU/half_adder.v ALU/sub_32bit.v ALU/bitwise_unit.v ^
    ALU/barrel_shifter.v ALU/comparator_unit.v ALU/booth_multiplier.v ^
    ALU/booth_encoder.v ALU/booth_step.v ALU/divider.v ^
    ALU/float_add_sub.v ALU/float_mul.v ALU/float_norm.v ALU/float_unpacker.v ^
    ALU/float_packer.v ALU/mantissa_aligner.v ALU/float_itof.v ALU/float_ftoi.v ^
    Pipeline/cpu_top.v Pipeline/csr_unit.v Pipeline/if_stage.v Pipeline/id_stage.v Pipeline/ex_stage.v ^
    Pipeline/mem_stage.v Pipeline/wb_stage.v Pipeline/control_unit.v ^
    Pipeline/imm_extender.v Pipeline/hazard_detection_unit.v Pipeline/forwarding_unit.v ^
    Pipeline/branch_hazard_handler.v Pipeline/branch_target_calc.v ^
    RegisterFile/register_file.v RegisterFile/reg32.v ^
    Memory/address_decoder.v Memory/ram.v Memory/rom.v Memory/rom_async_dp.v ^
    Memory/ram_async.v Memory/l1_cache.v Memory/addr_decomp.v Memory/cache_sram_way.v ^
    Peripherals/io_peripheral_bus.v Peripherals/gpio_top.v Peripherals/timer_top.v Peripherals/uart_top.v ^
    Peripherals/interrupt_controller.v
if %errorlevel% neq 0 exit /b 1

echo [3/3] Simulating %PROG%...
vvp universal_sim.vvp +PROG=Programs/%PROG%.mem +DUMP_START=%START% +DUMP_END=%END% +FLOAT=%FLOAT% %5 %6 %7 %8 %9

del universal_sim.vvp
