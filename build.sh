#!/bin/bash
clear
echo "==================================================="
echo "[TEST] Starting Automated Build Process"
echo "==================================================="

# Clear old logs
rm -f error.log

echo "[STEP 1/3] Assembling object code (rgbasm)..."
if ! rgbasm -o main.o main.asm 2> error.log; then
    echo "==================================================="
    echo "[FAILURE] Error in STEP 1 (rgbasm)!"
    echo "==================================================="
    cat error.log
    exit 1
fi

echo "[STEP 2/3] Linking files (rgblink)..."
if ! rgblink -o pong.gb main.o 2>> error.log; then
    echo "==================================================="
    echo "[FAILURE] Error in STEP 2 (rgblink)!"
    echo "==================================================="
    cat error.log
    exit 1
fi

echo "[STEP 3/3] Validating ROM header (rgbfix)..."
if ! rgbfix -v -p 0 pong.gb 2>> error.log; then
    echo "==================================================="
    echo "[FAILURE] Error in STEP 3 (rgbfix)!"
    echo "==================================================="
    cat error.log
    exit 1
fi

echo "==================================================="
echo "[SUCCESS] Build completed with no errors! ROM generated."
echo "==================================================="
rm -f error.log
exit 0