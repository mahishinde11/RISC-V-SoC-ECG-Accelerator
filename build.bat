@echo off
setlocal

:: --- Configuration ---
set OUT_DIR=output
set "TOOLCHAIN_DIR=..\..\RISC V BASE SOC\riscv-toolchain\xpack-riscv-none-elf-gcc-13.2.0-2\bin"
set "CC=%TOOLCHAIN_DIR%\riscv-none-elf-gcc.exe"
set "OBJCOPY=%TOOLCHAIN_DIR%\riscv-none-elf-objcopy.exe"
set "OBJDUMP=%TOOLCHAIN_DIR%\riscv-none-elf-objdump.exe"

set CFLAGS=-march=rv32i -mabi=ilp32 -O2 -nostdlib -ffreestanding -Wall
set LDFLAGS=-T link.ld -lgcc

set TARGET=%OUT_DIR%\firmware
set SRCS=start.S main.c

:: --- Build Process ---
echo [1/4] Cleaning old build...
if exist %OUT_DIR% rmdir /s /q %OUT_DIR%
mkdir %OUT_DIR%

echo [2/4] Compiling and Linking...
"%CC%" %CFLAGS% %SRCS% -o %TARGET%.elf %LDFLAGS%
if %ERRORLEVEL% NEQ 0 (
    echo Error: Compilation failed.
    exit /b %ERRORLEVEL%
)

echo [3/4] Generating Binary...
"%CC%" %CFLAGS% %SRCS% -o %TARGET%.elf %LDFLAGS%
"%OBJCOPY%" -O binary %TARGET%.elf %TARGET%.bin

echo [4/4] Converting to HEX...
python bin2hex.py %TARGET%.bin %TARGET%.hex
if %ERRORLEVEL% NEQ 0 (
    echo Error: HEX conversion failed.
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================
echo Build Successful!
echo HEX file: %TARGET%.hex
echo ========================================
echo.
