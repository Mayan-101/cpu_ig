@echo off
if "%~1"=="" (
    echo Usage: test_program.bat ^<program_name^>
    echo Example: .\Scripts\test_program.bat bubble_sort
    exit /b 1
)

set PROG=%~1
set ROM_FILE=Programs\rom_init.mem
set RAM_FILE=Programs\ram_init.mem

echo [1/3] Assembling %PROG%.asm...
python Assembler/assembler.py Programs/%PROG%.asm %ROM_FILE%
if %errorlevel% neq 0 exit /b 1

echo [2/3] Preparing Memory...
copy %ROM_FILE% rom_init.mem > nul
if exist Programs\%PROG%_ram.mem (
    copy Programs\%PROG%_ram.mem ram_init.mem > nul
) else (
    echo 0 > ram_init.mem
)

:: Core files
set ALU_CORE=ALU/alu_top.v ALU/alu_int.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v ALU/sub_32bit.v ALU/bitwise_unit.v ALU/barrel_shifter.v ALU/comparator_unit.v ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/divider.v ALU/float_add_sub.v ALU/float_mul.v ALU/float_norm.v ALU/float_unpacker.v ALU/float_packer.v ALU/mantissa_aligner.v
set PIPE_CORE=Pipeline/cpu_top.v Pipeline/pc_reg.v Pipeline/pipeline_reg.v Pipeline/control_unit.v Pipeline/imm_extender.v Pipeline/hazard_detection_unit.v Pipeline/forwarding_unit.v Pipeline/branch_hazard_handler.v Pipeline/branch_target_calc.v
set REG_CORE=RegisterFile/register_file.v RegisterFile/reg32.v
set MEM_CORE=Memory/address_decoder.v Memory/ram.v Memory/rom.v Memory/rom_async_dp.v Memory/ram_async.v Memory/l1_cache.v Memory/addr_decomp.v Memory/cache_sram_way.v
set PERI_CORE=Peripherals/io_peripheral_bus.v Peripherals/gpio.v Peripherals/timer.v Peripherals/uart.v Peripherals/interrupt_controller.v

echo [3/3] Simulating...
iverilog -o test_prog.vvp SystemTests/tb_program_tester.v SystemTests/system_cache_top.v %ALU_CORE% %PIPE_CORE% %REG_CORE% %MEM_CORE% %PERI_CORE%
if %errorlevel% neq 0 exit /b 1

vvp test_prog.vvp
del test_prog.vvp
del rom_init.mem
del ram_init.mem
