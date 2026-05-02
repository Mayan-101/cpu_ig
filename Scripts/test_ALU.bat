@echo off
set ALU_CORE=ALU/alu_top.v ALU/alu_int.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v ALU/sub_32bit.v ALU/bitwise_unit.v ALU/barrel_shifter.v ALU/comparator_unit.v ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/divider.v ALU/float_add_sub.v ALU/float_mul.v ALU/float_norm.v ALU/float_unpacker.v ALU/float_packer.v ALU/mantissa_aligner.v

echo Running ALU Tests...
iverilog -o test_alu.vvp Tests/tb_alu_top.v %ALU_CORE%
if %errorlevel% neq 0 (echo Compilation Failed! && exit /b 1)
vvp test_alu.vvp
del test_alu.vvp
pause
