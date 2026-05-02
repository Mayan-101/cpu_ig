@echo off
set ALU_CORE=ALU/alu_top.v ALU/alu_int.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v ALU/sub_32bit.v ALU/bitwise_unit.v ALU/barrel_shifter.v ALU/comparator_unit.v ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/divider.v ALU/float_add_sub.v ALU/float_mul.v ALU/float_norm.v ALU/float_unpacker.v ALU/float_packer.v ALU/mantissa_aligner.v
set PIPE_CORE=Pipeline/cpu_top.v Pipeline/pc_reg.v Pipeline/pipeline_reg.v Pipeline/control_unit.v Pipeline/imm_extender.v Pipeline/hazard_detection_unit.v Pipeline/forwarding_unit.v Pipeline/branch_hazard_handler.v Pipeline/branch_target_calc.v
set REG_CORE=RegisterFile/register_file.v RegisterFile/reg32.v RegisterFile/reg_bank8.v
set MEM_CORE=Memory/address_decoder.v Memory/ram.v Memory/rom.v Memory/rom_async_dp.v Memory/ram_async.v Memory/l1_cache.v Memory/addr_decomp.v Memory/cache_sram_way.v
set PERI_CORE=Peripherals/io_peripheral_bus.v Peripherals/gpio.v Peripherals/timer.v Peripherals/uart.v Peripherals/interrupt_controller.v

echo Starting Array Addition System Test...
copy Programs\rom_init.mem .
copy Programs\ram_init.mem .
iverilog -o array_test.vvp SystemTests/tb_system_array_add.v SystemTests/system_cache_top.v %ALU_CORE% %PIPE_CORE% %REG_CORE% %MEM_CORE% %PERI_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp array_test.vvp
