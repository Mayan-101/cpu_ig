@echo off
set ALU_CORE=ALU/alu_top.v ALU/alu_int.v ALU/cla_32bit.v ALU/cla_16bit.v ALU/cla_4bit.v ALU/full_adder.v ALU/half_adder.v ALU/sub_32bit.v ALU/bitwise_unit.v ALU/barrel_shifter.v ALU/comparator_unit.v ALU/booth_multiplier.v ALU/booth_encoder.v ALU/booth_step.v ALU/divider.v ALU/float_add_sub.v ALU/float_mul.v ALU/float_norm.v ALU/float_unpacker.v ALU/float_packer.v ALU/mantissa_aligner.v
set PIPE_CORE=Pipeline/cpu_top.v Pipeline/pc_reg.v Pipeline/pipeline_reg.v Pipeline/control_unit.v Pipeline/imm_extender.v Pipeline/hazard_detection_unit.v Pipeline/forwarding_unit.v Pipeline/branch_hazard_handler.v Pipeline/branch_target_calc.v
set REG_CORE=RegisterFile/register_file.v RegisterFile/reg32.v

echo Running Pipeline Tests...
echo [1/2] Testing CPU Top (Full Pipeline)...
iverilog -o test_pipe.vvp Tests/tb_cpu_top.v %PIPE_CORE% %ALU_CORE% %REG_CORE%
if %errorlevel% equ 0 (vvp test_pipe.vvp && del test_pipe.vvp)

echo [2/2] Testing Sequential ALU Integration...
iverilog -o test_cpu_core.vvp Tests/tb_cpu_core.v %PIPE_CORE% %ALU_CORE% %REG_CORE%
if %errorlevel% equ 0 (vvp test_cpu_core.vvp && del test_cpu_core.vvp)

pause
