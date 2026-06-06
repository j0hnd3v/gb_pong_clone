@echo off
cls
echo ===================================================
echo [TEST] Starting Automated Build Process
echo ===================================================

:: Clear old logs
if exist error.log del error.log

echo [STEP 1/3] Assembling object code (rgbasm)...
rgbasm -o main.o main.asm 2> error.log
if errorlevel 1 goto failure_step1

echo [STEP 2/3] Linking files (rgblink)...
rgblink -o pong.gb main.o 2>> error.log
if errorlevel 1 goto failure_step2

echo [STEP 3/3] Validating ROM header (rgbfix)...
rgbfix -v -p 0 pong.gb 2>> error.log
if errorlevel 1 goto failure_step3

echo ===================================================
echo [SUCCESS] Build completed with no errors! ROM generated.
echo ===================================================
if exist error.log del error.log
pause
exit /b 0

:failure_step1
echo ===================================================
echo [FAILURE] Error in STEP 1 (rgbasm)!
echo ===================================================
type error.log
pause
exit /b 1

:failure_step2
echo ===================================================
echo [FAILURE] Error in STEP 2 (rgblink)!
echo ===================================================
type error.log
pause
exit /b 1

:failure_step3
echo ===================================================
echo [FAILURE] Error in STEP 3 (rgbfix)!
echo ===================================================
type error.log
pause
exit /b 1