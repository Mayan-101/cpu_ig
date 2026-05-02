@echo off
set MEM_CORE=Memory/address_decoder.v Memory/ram.v Memory/rom.v Memory/rom_async_dp.v Memory/ram_async.v Memory/l1_cache.v Memory/addr_decomp.v Memory/cache_sram_way.v

echo Running Memory Subsystem Tests...
echo [1/3] Testing RAM...
iverilog -o test_ram.vvp Tests/tb_ram.v Memory/ram.v
if %errorlevel% equ 0 (vvp test_ram.vvp && del test_ram.vvp)

echo [2/3] Testing Address Decoder...
iverilog -o test_dec.vvp Tests/tb_address_decoder.v Memory/address_decoder.v
if %errorlevel% equ 0 (vvp test_dec.vvp && del test_dec.vvp)

echo [3/3] Testing Cache Core...
iverilog -o test_cache.vvp Tests/tb_cache_core_4way.v Memory/cache_core_4way.v Memory/cache_sram_way.v Memory/addr_decomp.v
if %errorlevel% equ 0 (vvp test_cache.vvp && del test_cache.vvp)

pause
