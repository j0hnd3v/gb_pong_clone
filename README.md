# GB-Pong-clone

A nostalgic Game Boy implementation of the classic Pong game, created purely for educational purposes, entertainment, and as a personal hobby project.

This project is not meant to be finished, polished, or updated. It stands as a frozen snapshot in time—much like an old, fading photograph of a lost memory. 

## Technical Details

The codebase relies on specific legacy tools and definitions from the Game Boy development ecosystem:
* **Assembler/Linker:** [RGBDS](https://github.com/gbdev/rgbds/releases/tag/v0.5.2/) version **0.5.2**
* **Hardware Definitions:** [hardware.inc](https://github.com/gbdev/hardware.inc/releases/tag/v4.5) version **4.5.0**

*Note: Attempting to build this project with newer versions of RGBDS may result in compilation errors due to breaking syntax changes in the toolchain.*

## Repository Structure

* `main.asm` - Core game loop, system initialization, and input tracking.
* `physics.asm` - Ball movement behavior, bounce logic, and CPU AI calculations.
* `sprites.asm` - OAM shadow buffers and rendering handlers for paddles and scores.
* `graphics.asm` - Hardcoded tile data for the visual assets (ball, paddles, typography).
* `video.asm` - Memory safe VRAM copying routines and LCD management.
* `constants.inc` - Global gameplay constraints.

## How to Build

If you happen to have the legacy RGBDS 0.5.2 environment set up, you can compile the ROM using the automated script included in this repository:

### Windows
Run the automated batch script:
```bash
build.bat
```

Linux / macOS
Make the shell script executable and run it:

```Bash
chmod +x build.sh
./build.sh
```
Manual Compilation
Alternatively, you can run the RGBDS toolchain commands manually in your terminal:

```Bash
# 1. Assemble the source file into an object file
rgbasm -o main.o main.asm

# 2. Link the object file to create the Game Boy ROM
rgblink -o gbpong.gb -n gbpong.sym main.o

# 3. Fix the ROM header (checksums, title, and Nintendo logo verification)
rgbfix -v -p 0 gbpong.gb
```
Once completed, you will look at a fresh gbpong.gb file ready to be loaded into your favorite emulator (like BGB, SameBoy, or MGBA) or flashed onto a real cartridge!
