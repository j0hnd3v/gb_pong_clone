; ******************************************************************************
; * GAME BOY HARDWARE DEFINITIONS (hardware.inc v4.5.0)
; ******************************************************************************
; * Hey there! This file is the "magic translator" for the Game Boy hardware.
; * Instead of forcing you to memorize scary hex addresses like $FF40, this 
; * file lets you write human-readable words like "rLCDC". 
; * Think of it as a dictionary that maps names to the console's physical organs!
; ******************************************************************************

; --- RGBDS COMPILER VERSION CHECK ---
; This prevents the script from building if the user is using an outdated toolchain.
IF __RGBDS_MAJOR__ == 0 && __RGBDS_MINOR__ < 5
    FAIL "This version of 'hardware.inc' requires RGBDS version 0.5.0 or later."
ENDC

; --- INCLUDE GUARD ---
; This prevents the compiler from reading this file twice if it's included in multiple places.
    IF !DEF(HARDWARE_INC)
DEF HARDWARE_INC EQU 1

; --- VERSION CHECK MACRO ---
; Allows your main code to throw a warning if your file version is too old.
MACRO rev_Check_hardware_inc
    IF  \1 > 4.5 ; Your current version is 4.5
        WARN    "Version \1 or later of 'hardware.inc' is required."
    ENDC
ENDM

; ==============================================================================
; SYSTEM MEMORY MAP CONFIGURATIONS (Where everything lives in RAM)
; ==============================================================================
DEF _VRAM        EQU $8000 ; Video RAM: Where your graphics tiles are stored ($8000 -> $9FFF)
DEF _SCRN0       EQU $9800 ; Background Map 0: Tells the system which tiles to show on screen
DEF _SCRN1       EQU $9C00 ; Background Map 1: Alternative map layer location
DEF _SRAM        EQU $A000 ; Save RAM: External cartridge RAM used for keeping save files
DEF _RAM         EQU $C000 ; Work RAM (WRAM): Main system memory scratchpad for game variables
DEF _RAMBANK     EQU $D000 ; WRAM Bank 1: Extra switchable RAM bank on the Game Boy Color
DEF _OAMRAM      EQU $FE00 ; Object Attribute Memory: Where sprite locations/attributes live
DEF _IO          EQU $FF00 ; Hardware I/O Registers: The ports that control hardware chips
DEF _AUD3WAVERAM EQU $FF30 ; Sound Channel 3 Waveform RAM: Custom sound wave patterns go here
DEF _HRAM        EQU $FF80 ; High RAM: Super fast zero-page RAM space ($FF80 -> $FFFE)

; ==============================================================================
; MEMORY BANK CONTROLLER 5 (MBC5) SETUP
; ==============================================================================
; Cartridges use MBC chips to swap different banks of ROM/RAM in and out of view.
DEF rRAMG        EQU $0000 ; RAM Gate: Write $0A here to enable saving, $00 to lock it
DEF rROMB0       EQU $2000 ; ROM Bank Select (Low 8 bits): Choose which part of the game to read
DEF rROMB1       EQU $3000 ; ROM Bank Select (High bit): For massive games over 4 Megabytes
DEF rRAMB        EQU $4000 ; RAM Bank Select: Swaps save files, or triggers a rumble motor pack!


; ==============================================================================
; HARDWARE PORT REGISTERS
; ==============================================================================

; --- rP1 ($FF00): INPUT JOYPAD PORT ---
; The Game Boy reads buttons by setting pins low (0) and reading back the values.
DEF rP1 EQU $FF00

; Mask Flags (Bitmasks)
DEF P1F_5        EQU %00100000 ; Select Pin 15: Set to 0 to read A, B, Select, Start
DEF P1F_4        EQU %00010000 ; Select Pin 14: Set to 0 to read Right, Left, Up, Down
DEF P1F_3        EQU %00001000 ; Input Pin 13: Reads Start  or Down
DEF P1F_2        EQU %00000100 ; Input Pin 12: Reads Select or Up
DEF P1F_1        EQU %00000010 ; Input Pin 11: Reads B      or Left
DEF P1F_0        EQU %00000001 ; Input Pin 10: Reads A      or Right

; Developer Friendly Short-cuts
DEF P1F_GET_DPAD EQU P1F_5     ; Mask to query D-Pad cross direction buttons
DEF P1F_GET_BTN  EQU P1F_4     ; Mask to query Action face buttons
DEF P1F_GET_NONE EQU P1F_4 | P1F_5 ; Shuts down input polling pins completely

; --- rSB & rSC ($FF01 / $FF02): LINK CABLE SERIAL PORTS ---
DEF rSB EQU $FF01 ; Serial Buffer: Holds the single byte being transferred over the wire
DEF rSC EQU $FF02 ; Serial Control: Manages how data transfers execute

; Serial Bitmasks (Flags)
DEF SCF_START  EQU %10000000 ; Bit 7 Flag: Set to 1 to begin pushing data to the other player
DEF SCF_SPEED  EQU %00000010 ; Bit 1 Flag: GBC mode exclusive fast data rate clock
DEF SCF_SOURCE EQU %00000001 ; Bit 0 Flag: 1 = Use internal Game Boy clock, 0 = External friend's clock

; Raw Bit Positions (For BIT, SET, RES instructions)
DEF SCB_START  EQU 7
DEF SCB_SPEED  EQU 1
DEF SCB_SOURCE EQU 0

; --- TIMERS & COUNTERS ($FF04 - $FF07) ---
DEF rDIV  EQU $FF04 ; Divider: Automatically ticks up at 16384Hz. Writing anything resets it to 0.
DEF rTIMA EQU $FF05 ; Timer Counter: Ticks up based on frequency settings. Triggers interrupt on overflow.
DEF rTMA  EQU $FF06 ; Timer Modulo: When TIMA overflows, it automatically reloads this value.
DEF rTAC  EQU $FF07 ; Timer Control: Turns the timer on/off and selects its ticking speed.

; Timer Bitmasks
DEF TACF_START  EQU %00000100 ; Turn timer ON
DEF TACF_STOP   EQU %00000000 ; Turn timer OFF
DEF TACF_4KHZ   EQU %00000000 ; Speed mode 0: 4096 ticks per second
DEF TACF_16KHZ  EQU %00000011 ; Speed mode 3: 16384 ticks per second
DEF TACF_65KHZ  EQU %00000010 ; Speed mode 2: 65536 ticks per second
DEF TACF_262KHZ EQU %00000001 ; Speed mode 1: 262144 ticks per second

DEF TACB_START  EQU 2         ; Bit position index for controlling timer power status

; --- rIF ($FF0F): INTERRUPT FLAG (The Radar) ---
; When hardware needs the CPU to run an event (like a VBlank), it sets a bit here to 1.
DEF rIF EQU $FF0F


; ==============================================================================
; SOUND REGISTER COMPLEX ($FF10 - $FF26)
; ==============================================================================

; --- AUDIO CHANNEL 1: SQUARE WAVE WITH SWEEP ---
DEF rNR10      EQU $FF10
DEF rAUD1SWEEP EQU rNR10      ; Sweep Register: Automatically alters sound pitch over time
DEF AUD1SWEEP_UP   EQU %00000000 ; Frequency slides upward
DEF AUD1SWEEP_DOWN EQU %00001000 ; Frequency slides downward

DEF rNR11      EQU $FF11
DEF rAUD1LEN   EQU rNR11      ; Length / Duty Cycle: Controls sound duration and tone thickness

DEF rNR12      EQU $FF12
DEF rAUD1ENV   EQU rNR12      ; Volume Envelope: Sets start volume and fade-in/fade-out steps

DEF rNR13      EQU $FF13
DEF rAUD1LOW   EQU rNR13      ; Frequency Low: Lower 8-bits of raw pitch calculation data (Write Only)

DEF rNR14      EQU $FF14
DEF rAUD1HIGH  EQU rNR14      ; Frequency High: Top 3-bits of pitch + trigger activation flags

; --- AUDIO CHANNEL 2: STANDARD SQUARE WAVE ---
; (Identical to Channel 1, but cannot perform pitch slide sweeps)
DEF rNR21      EQU $FF16
DEF rAUD2LEN   EQU rNR21
DEF rNR22      EQU $FF17
DEF rAUD2ENV   EQU rNR22
DEF rNR23      EQU $FF18
DEF rAUD2LOW   EQU rNR23
DEF rNR24      EQU $FF19
DEF rAUD2HIGH  EQU rNR24

; --- AUDIO CHANNEL 3: CUSTOM WAVEFORM CHIP ---
; Plays low-fi digital music patterns stored in Wave RAM ($FF30). Great for synth basslines!
DEF rNR30      EQU $FF1A
DEF rAUD3ENA   EQU rNR30      ; Audio Channel 3 Power Switch
DEF AUD3ENA_OFF EQU %00000000
DEF AUD3ENA_ON  EQU %10000000

DEF rNR31      EQU $FF1B
DEF rAUD3LEN   EQU rNR31      ; Playback Length timer

DEF rNR32      EQU $FF1C
DEF rAUD3LEVEL EQU rNR32      ; Digital Volume Shifter (Mute, 100%, 50%, 25% output scaling)
DEF AUD3LEVEL_MUTE EQU %00000000
DEF AUD3LEVEL_100  EQU %00100000
DEF AUD3LEVEL_50   EQU %01000000
DEF AUD3LEVEL_25   EQU %01100000

DEF rNR33      EQU $FF1D
DEF rAUD3LOW   EQU rNR33
DEF rNR34      EQU $FF1E
DEF rAUD3HIGH  EQU rNR34

; --- AUDIO CHANNEL 4: WHITE NOISE GENERATOR ---
; Generates randomized static sound effects. Perfect for explosions, snare drums, or footsteps!
DEF rNR41      EQU $FF20
DEF rAUD4LEN   EQU rNR41
DEF rNR42      EQU $FF21
DEF rAUD4ENV   EQU rNR42

DEF rNR43      EQU $FF22
DEF rAUD4POLY  EQU rNR43      ; Polynomial Counter: Alters randomness algorithm variables to change texture
DEF AUD4POLY_15STEP EQU %00000000 ; Long pattern sequence (Standard static roar)
DEF AUD4POLY_7STEP  EQU %00001000 ; Short pattern sequence (Metallic sci-fi hum buzz)

DEF rNR44      EQU $FF23
DEF rAUD4GO    EQU rNR44      ; Sound trigger and length counter controls

; --- GLOBAL SOUND ROUTERS & MIXERS ---
DEF rNR50   EQU $FF24
DEF rAUDVOL EQU rNR50         ; Master Speakers Volume Control (Left and Right mix levels)
DEF AUDVOL_VIN_LEFT  EQU %10000000 ; Pass external cartridge sound input to left side speaker
DEF AUDVOL_VIN_RIGHT EQU %00001000 ; Pass external cartridge sound input to right side speaker

DEF rNR51    EQU $FF25
DEF rAUDTERM EQU rNR51        ; Channel Panning Switch: Sends individual channels to Left, Right, or Both speakers
; Channel Left Outputs
DEF AUDTERM_4_LEFT  EQU %10000000
DEF AUDTERM_3_LEFT  EQU %01000000
DEF AUDTERM_2_LEFT  EQU %00100000
DEF AUDTERM_1_LEFT  EQU %00010000
; Channel Right Outputs
DEF AUDTERM_4_RIGHT EQU %00001000
DEF AUDTERM_3_RIGHT EQU %00000100
DEF AUDTERM_2_RIGHT EQU %00000010
DEF AUDTERM_1_RIGHT EQU %00000001

DEF rNR52   EQU $FF26
DEF rAUDENA EQU rNR52         ; Global Sound Core Killswitch. Set to 0 to save battery power!
DEF AUDENA_ON  EQU %10000000  ; Sound System operational
DEF AUDENA_OFF EQU %00000000  ; Complete audio block shutdown (Erases all audio registers)


; ==============================================================================
; VIDEO REGISTERS & LCD GRAPHICS DRIVER CONFIGURATIONS
; ==============================================================================

; --- rLCDC ($FF40): MASTER DISPLAY CONTROL ---
; The main switchboard governing screen composition layers.
DEF rLCDC EQU $FF40

; Bitmasks
DEF LCDCF_OFF      EQU %00000000 ; Shut down whole screen system (Must be done during VBlank only!)
DEF LCDCF_ON       EQU %10000000 ; Power up video rendering hardware pipeline
DEF LCDCF_WIN9800  EQU %00000000 ; Render HUD Overlay window layer using memory map $9800
DEF LCDCF_WIN9C00  EQU %01000000 ; Render HUD Overlay window layer using memory map $9C00
DEF LCDCF_WINOFF   EQU %00000000 ; Turn off floating HUD overlay layer completely
DEF LCDCF_WINON    EQU %00100000 ; Turn on floating HUD overlay layer
DEF LCDCF_BG8800   EQU %00000000 ; Set font tile texture atlas starting space layout to $8800
DEF LCDCF_BG8000   EQU %00010000 ; Set font tile texture atlas starting space layout to $8000
DEF LCDCF_BG9800   EQU %00000000 ; Render gameplay background layer using memory map $9800
DEF LCDCF_BG9C00   EQU %00001000 ; Render gameplay background layer using memory map $9C00
DEF LCDCF_OBJ8     EQU %00000000 ; Render actors/sprites as tiny 8x8 pixel blocks
DEF LCDCF_OBJ16    EQU %00000100 ; Render actors/sprites as double-tall 8x16 pixel blocks
DEF LCDCF_OBJOFF   EQU %00000000 ; Hide moving sprites/objects layer completely
DEF LCDCF_OBJON    EQU %00000010 ; Turn on moving sprites/objects layer
DEF LCDCF_BGOFF    EQU %00000000 ; Hide background wallpaper layer (Turns it plain white)
DEF LCDCF_BGON     EQU %00000001 ; Show background wallpaper layer

; Bit Position Indexes
DEF LCDCB_ON       EQU 7
DEF LCDCB_WIN9C00  EQU 6
DEF LCDCB_WINON    EQU 5
DEF LCDCB_BG8000   EQU 4
DEF LCDCB_BG9C00   EQU 3
DEF LCDCB_OBJ16    EQU 2
DEF LCDCB_OBJON    EQU 1
DEF LCDCB_BGON     EQU 0

; --- rSTAT ($FF41): LCD DISPLAY DRAWING STATUS MONITOR ---
DEF rSTAT EQU $FF41

; Bitmasks
DEF STATF_LYC     EQU  %01000000 ; Interrupt Trigger: Fire when your scanline matches a target line
DEF STATF_MODE10  EQU  %00100000 ; Interrupt Trigger: Fire during OAM scanning operations
DEF STATF_MODE01  EQU  %00010000 ; Interrupt Trigger: Fire during VBlank pause refresh intervals
DEF STATF_MODE00  EQU  %00001000 ; Interrupt Trigger: Fire during HBlank pixel scan line completions
DEF STATF_LYCF    EQU  %00000100 ; Coincidence Match Status Flag (1 = Scan line matches rLYC target)
DEF STATF_HBL     EQU  %00000000 ; Mode Flag: Electron beam is flying back left horizontally (Safe for VRAM)
DEF STATF_VBL     EQU  %00000001 ; Mode Flag: Electron beam is resting at bottom line (Safe for everything)
DEF STATF_OAM     EQU  %00000010 ; Mode Flag: System reading OAM table (Do not modify sprites right now)
DEF STATF_LCD     EQU  %00000011 ; Mode Flag: System rendering pixels (VRAM/OAM fully locked out by chip hardware)
DEF STATF_BUSY    EQU  %00000010 ; Quick access mask to identify unsafe modification intervals

; Bit Positions
DEF STATB_LYC     EQU  6
DEF STATB_MODE10  EQU  5
DEF STATB_MODE01  EQU  4
DEF STATB_MODE00  EQU  3
DEF STATB_LYCF    EQU  2
DEF STATB_BUSY    EQU  1

; --- SCREEN CAMERAS & VIDEO SYNCHRONIZATION PORTS ---
DEF rSCY  EQU $FF42 ; Scroll Y: Shifts background map window positioning up or down
DEF rSCX  EQU $FF43 ; Scroll X: Shifts background map window positioning left or right
DEF rLY   EQU $FF44 ; Current Scanline Tracker: Tells you exactly which row out of 0-153 is drawing right now.
DEF rLYC  EQU $FF45 ; Scanline Compare Target: Set a specific line number here to trip a hblank sync flag interrupt.
DEF rDMA  EQU $FF46 ; Direct Memory Access Launchpad: Write $C0 here to flash sprite shadow table straight to chip RAM!

; --- RETAIN PALETTES SYSTEMS (Classic Monochrome DMG Gray Shading Arrays) ---
DEF rBGP  EQU $FF47 ; Background Palette Shading Profile configurations
DEF rOBP0 EQU $FF48 ; Moving Sprite Objects Layer Shading Profile 0 configurations
DEF rOBP1 EQU $FF49 ; Moving Sprite Objects Layer Shading Profile 1 configurations

; --- SCREEN WINDOW HUD POSITIONING SLIDERS ---
DEF rWY   EQU $FF4A ; Window HUD Layer Y Vertical Screen offset pixel line margin
DEF rWX   EQU $FF4B ; Window HUD Layer X Horizontal Screen offset pixel line margin
DEF WX_OFS EQU 7     ; Window hardware is shifted by 7 pixels internally. Add this offset to balance screen placement!


; ==============================================================================
; GAME BOY COLOR EXCLUSIVE CONFIGURATION PORTS (CGB Modes ONLY)
; ==============================================================================
DEF rKEY1 EQU $FF4D
DEF rSPD  EQU rKEY1 ; CPU Speed Controller Engine
DEF KEY1F_DBLSPEED EQU %10000000 ; Speed Status Indicator: 1 = Running double performance speed (8.4Mhz)
DEF KEY1F_PREPARE  EQU %00000001 ; Turbo Trigger Arming wire: Set to 1, then execute STOP instruction to toggle speed modes

DEF rVBK EQU $FF4F ; VRAM Bank Switcher: Swap between Video RAM block pages 0 and 1

; --- High Speed Hardware Flash Memory Pipes (HDMA Data Blitters) ---
DEF rHDMA1 EQU $FF51 ; Transfer Source tracking location High Address byte
DEF rHDMA2 EQU $FF52 ; Transfer Source tracking location Low Address byte
DEF rHDMA3 EQU $FF53 ; Destination Target tracking location High Address byte
DEF rHDMA4 EQU $FF54 ; Destination Target tracking location Low Address byte
DEF rHDMA5 EQU $FF55 ; Transfer Command Dispatch Controller / Length block calculator

; HDMA Bitmasks
DEF HDMA5F_MODE_GP  EQU %00000000 ; Mode select: Process General Purpose flash copy block instantly
DEF HDMA5F_MODE_HBL EQU %10000000 ; Mode select: Process distributed trickle copy updates line-by-line during HBlanks
DEF HDMA5B_MODE     EQU 7         ; Selection Bit tracking index position
DEF HDMA5F_BUSY     EQU %10000000 ; Read Monitor Flag: 0 = Blitter active, 1 = Transfer operation finished completely

; --- Infrared Communication Transceiver Port ---
DEF rRP EQU $FF56 
DEF RPF_ENREAD   EQU %11000000 ; Read Sensor Enable Command mask strings
DEF RPF_DATAIN   EQU %00000010 ; Input State: 0 = Detecting physical incoming light beam right now
DEF RPF_WRITE_HI EQU %00000001 ; Output emitter Control wire: Turn infrared bulb ON
DEF RPF_WRITE_LO EQU %00000000 ; Output emitter Control wire: Turn infrared bulb OFF

; --- Color Hardware Palettes Mapping Address Directories ---
DEF rBCPS EQU $FF68 ; Background Color Register Directory Selector Interface
DEF BCPSF_AUTOINC EQU %10000000 ; Auto Increment: Moves pointer target index up automatically after writes
DEF BCPSB_AUTOINC EQU 7

DEF rBCPD EQU $FF69 ; Background Color Palette RAM Write Port data gateway

DEF rOCPS EQU $FF6A ; Object Sprite Color Register Directory Selector Interface
DEF OCPSF_AUTOINC EQU %10000000 ; Auto Increment pointer helper
DEF OCPSB_AUTOINC EQU 7

DEF rOCPD EQU $FF6B ; Object Sprite Color Palette RAM Write Port data gateway

DEF rSVBK EQU $FF70 ; Work RAM Bank Select: Swaps standard onboard scratch space across banks 1 to 7

; --- Real Time Digital Audio PCM Output Monitors ---
DEF rPCM12 EQU $FF76 ; Live Volume Output levels for Sound Channels 1 (low nibble) and 2 (high nibble)
DEF rPCM34 EQU $FF77 ; Live Volume Output levels for Sound Channels 3 (low nibble) and 4 (high nibble)


; ==============================================================================
; rIE ($FFFF): INTERRUPT ENABLE SWITCHBOARD MASTER
; ==============================================================================
; Tell the processor exactly which hardware alarms it is allowed to respond to!
DEF rIE EQU $FFFF

; Bitmasks
DEF IEF_HILO   EQU %00010000 ; Button Press Interrupt activation (Joypad input triggers)
DEF IEF_SERIAL EQU %00001000 ; Link Cable Serial byte transfer complete activation
DEF IEF_TIMER  EQU %00000100 ; Clock Timer Counter Overflow alert activation
DEF IEF_STAT   EQU %00000010 ; LCD Display status update sync alert activation
DEF IEF_VBLANK EQU %00000001 ; Vertical Blank refresh loop start activation

; Bit Positions
DEF IEB_HILO   EQU 4
DEF IEB_SERIAL EQU 3
DEF IEB_TIMER  EQU 2
DEF IEB_STAT   EQU 1
DEF IEB_VBLANK EQU 0


; ==============================================================================
; COMPOSITE RE-USE AUDIO SUB-SYSTEM PARAMETERS FLAGS
; ==============================================================================

; --- Square Wave Tone Duty Profiles ---
DEF AUDLEN_DUTY_12_5    EQU %00000000 ; Thin, piercing sound (12.5% pulse width wave profile)
DEF AUDLEN_DUTY_25      EQU %01000000 ; Standard chip sound (25% pulse width wave profile)
DEF AUDLEN_DUTY_50      EQU %10000000 ; Perfect hollow square wave (50% pulse width wave profile like NES)
DEF AUDLEN_DUTY_75      EQU %11000000 ; Wide dense sound profile (75% pulse width wave profile)

; --- Volume Envelope Direction Profiles ---
DEF AUDENV_UP           EQU %00001000 ; Crescendo: Sound fades upwards louder over time
DEF AUDENV_DOWN         EQU %00000000 ; Decrescendo: Sound decays down quieter into silence

; --- Channel Initial Triggers ---
DEF AUDHIGH_RESTART     EQU %10000000 ; Boot trigger: Resets and physically strikes sound channel notes
DEF AUDHIGH_LENGTH_ON   EQU %01000000 ; Automatic hardware shutoff: Channel silences once length timer hits zero
DEF AUDHIGH_LENGTH_OFF  EQU %00000000 ; Continuous sound sustain mode: Note rings forever until hand silenced


; ==============================================================================
; RETRO HARDWARE CONSOLE BOOTUP SIGNATURE STRINGS
; ==============================================================================
; When the internal Nintendo boot animation ends, CPU registries are preloaded 
; with specific signature codes indicating exactly what device the user is playing on.
DEF BOOTUP_A_DMG    EQU $01 ; Registers A value = Classic monochrome Game Boy brick console
DEF BOOTUP_A_CGB    EQU $11 ; Registers A value = High Performance Color Game Boy console
DEF BOOTUP_A_MGB    EQU $FF ; Registers A value = Slim Pocket Game Boy console units

DEF BOOTUP_B_CGB    EQU %00000000 ; Register B value = Running inside native clear Game Boy Color hardware
DEF BOOTUP_B_AGB    EQU %00000001 ; Register B value = Running inside Game Boy Advance backwards compatibility hardware


; ==============================================================================
; CARTRIDGE FIRMWARE MANIFEST DATA LOOKUP REGISTERS
; ==============================================================================

; Color Modes Compatibility Byte configurations ($0143 Header offset position)
DEF CART_COMPATIBLE_DMG     EQU $00 ; Monochrome Exclusive execution blocks only
DEF CART_COMPATIBLE_DMG_GBC EQU $80 ; Enhanced Hybrid: Supports color but works fine on basic black & white bricks
DEF CART_COMPATIBLE_GBC     EQU $C0 ; Color exclusive: Crashes out and prints error screen on older bricks

; Expansion Layout Indicators ($0146 Header offset position)
DEF CART_INDICATOR_GB        EQU $00 ; Standard Portable Console Game Cartridge
DEF CART_INDICATOR_SGB       EQU $03 ; Super Game Boy SNES adapter television features engine active

; Cartridge Mapping Hardware Chipset ID configurations ($0147 Header offset position)
DEF CART_ROM                     EQU $00 ; Pure basic single game chip without memory controllers
DEF CART_ROM_MBC1                EQU $01 ; Standard Memory Bank Controller chip 1
DEF CART_ROM_MBC1_RAM            EQU $02
DEF CART_ROM_MBC1_RAM_BAT        EQU $03 ; MBC1 with saving battery backups
DEF CART_ROM_MBC2                EQU $05
DEF CART_ROM_MBC2_BAT            EQU $06
DEF CART_ROM_RAM                 EQU $08
DEF CART_ROM_RAM_BAT             EQU $09
DEF CART_ROM_MMM01               EQU $0B
DEF CART_ROM_MMM01_RAM           EQU $0C
DEF CART_ROM_MMM01_RAM_BAT       EQU $0D
DEF CART_ROM_MBC3_BAT_RTC        EQU $0F ; MBC3 chip equipped with physical real-time battery clocks (Pokémon games!)
DEF CART_ROM_MBC3_RAM_BAT_RTC    EQU $10
DEF CART_ROM_MBC3                EQU $11
DEF CART_ROM_MBC3_RAM            EQU $12
DEF CART_ROM_MBC3_RAM_BAT        EQU $13
DEF CART_ROM_MBC5                EQU $19 ; Modernized precision memory mapper 5 engine
DEF CART_ROM_MBC5_BAT            EQU $1A
DEF CART_ROM_MBC5_RAM_BAT        EQU $1B
DEF CART_ROM_MBC5_RUMBLE         EQU $1C ; Game Boy Rumble motor force feedback expansion cartridges
DEF CART_ROM_MBC5_RAM_RUMBLE     EQU $1D
DEF CART_ROM_MBC5_RAM_BAT_RUMBLE EQU $1E
DEF CART_ROM_MBC7_RAM_BAT_GYRO   EQU $22 ; Motion control tilt-sensor motion tracker chip gyros (WarioWare Twisted!)
DEF CART_ROM_POCKET_CAMERA       EQU $FC ; Dedicated Game Boy Camera image processor hardware
DEF CART_ROM_BANDAI_TAMA5        EQU $FD ; Specialized internal digital pet clock microcontrollers
DEF CART_ROM_HUDSON_HUC3         EQU $FE
DEF CART_ROM_HUDSON_HUC1         EQU $FF

; Game Storage File Size tiers ($0148 Header offset position)
DEF CART_ROM_32KB   EQU $00 ; 32 Kilobytes Total Space (2 ROM Banks - No MBC chip needed)
DEF CART_ROM_64KB   EQU $01 ; 64 Kilobytes Total Space (4 ROM Banks)
DEF CART_ROM_128KB  EQU $02 ; 128 Kilobytes Total Space (8 ROM Banks)
DEF CART_ROM_256KB  EQU $03 ; 256 Kilobytes Total Space (16 ROM Banks)
DEF CART_ROM_512KB  EQU $04 ; 512 Kilobytes Total Space (32 ROM Banks)
DEF CART_ROM_1024KB EQU $05 ; 1 Megabyte Total Space (64 ROM Banks)
DEF CART_ROM_2048KB EQU $06 ; 2 Megabytes Total Space (128 ROM Banks)
DEF CART_ROM_4096KB EQU $07 ; 4 Megabytes Total Space (256 ROM Banks)
DEF CART_ROM_8192KB EQU $08 ; 8 Megabytes Total Space (512 ROM Banks)
DEF CART_ROM_1152KB EQU $52 ; Custom 72 Bank sizes configurations
DEF CART_ROM_1280KB EQU $53 ; Custom 80 Bank sizes configurations
DEF CART_ROM_1536KB EQU $54 ; Custom 96 Bank sizes configurations

; Save File Cartridge RAM Space Allocation limits ($0149 Header offset position)
DEF CART_SRAM_NONE  EQU 0   ; No active battery save file allocation spaces
DEF CART_SRAM_8KB   EQU 2   ; 8 Kilobytes save space (1 Memory page bank)
DEF CART_SRAM_32KB  EQU 3   ; 32 Kilobytes save space (4 Memory page banks)
DEF CART_SRAM_128KB EQU 4   ; 128 Kilobytes save space (16 Memory page banks)

DEF CART_SRAM_ENABLE  EQU $0A ; Secret code to unlock write access to battery save RAM
DEF CART_SRAM_DISABLE EQU $00 ; Lock save RAM to prevent accidental corruptions or bugs

; Cartridge Global Target Market Distribution Regions ($014A Header offset position)
DEF CART_DEST_JAPANESE     EQU $00 ; Japanese domestic market territory cartridge distribution
DEF CART_DEST_NON_JAPANESE EQU $01 ; Worldwide international market territory cartridge distribution


; ==============================================================================
; USER HARDWARE CONTROLLER INPUT CONSTANT MATRICES
; ==============================================================================

; Value Mask Flag Bits Configuration Array sets (For verifying keys from register A)
DEF PADF_DOWN   EQU $80
DEF PADF_UP     EQU $40
DEF PADF_LEFT   EQU $20
DEF PADF_RIGHT  EQU $10
DEF PADF_START  EQU $08
DEF PADF_SELECT EQU $04
DEF PADF_B      EQU $02
DEF PADF_A      EQU $01

; Numeric Bit Position Layout indices (For checking lines via the BIT instruction)
DEF PADB_DOWN   EQU $7
DEF PADB_UP     EQU $6
DEF PADB_LEFT   EQU $5
DEF PADB_RIGHT  EQU $4
DEF PADB_START  EQU $3
DEF PADB_SELECT EQU $2
DEF PADB_B      EQU $1
DEF PADB_A      EQU $0


; ==============================================================================
; HARDWARE PHYSICAL SCREEN PROPERTY DIMENSION MATRICES
; ==============================================================================
DEF SCRN_X    EQU 160 ; Display Screen Width boundary limits (160 horizontal pixels)
DEF SCRN_Y    EQU 144 ; Display Screen Height boundary limits (144 vertical pixels)
DEF SCRN_X_B  EQU 20  ; Screen display resolution measured in complete structural tiles widthwide
DEF SCRN_Y_B  EQU 18  ; Screen display resolution measured in complete structural tiles heightwide

DEF SCRN_VX   EQU 256 ; Virtual background grid sheet loop dimensions limit widths (256 pixels)
DEF SCRN_VY   EQU 256 ; Virtual background grid sheet loop dimensions limit heights (256 pixels)
DEF SCRN_VX_B EQU 32  ; Background dimensions map measured in complete rows width-wise
DEF SCRN_VY_B EQU 32  ; Background dimensions map measured in complete rows height-wise


; ==============================================================================
; OBJECT ATTRIBUTES MEMORY STRUCTURE LAYOUT REGISTERS (OAM Engine Specs)
; ==============================================================================

; --- AUTOMATED OFFSET MEMORY COUNTER STACK REGISTERS ---
; These definitions help organize memory variables within an object structure data index block.
RSRESET
DEF OAMA_Y              RB  1   ; Relative Byte 0: Object spatial Y Coordinate placement profile
DEF OAMA_X              RB  1   ; Relative Byte 1: Object spatial X Coordinate placement profile
DEF OAMA_TILEID         RB  1   ; Relative Byte 2: Texture Atlas Graphic reference pointer link ID
DEF OAMA_FLAGS          RB  1   ; Relative Byte 3: Flip parameters, palette modes, rendering priority
DEF sizeof_OAM_ATTRS    RB  0   ; Final calculation size result tracker (4 bytes total per sprite object)

; Hardware Offset Padding: Sprites are shifted off screen by default. Add these to correct coordinates.
DEF OAM_Y_OFS EQU 16 ; Add 16 to a screen Y coordinate to make a sprite show up in the right spot
DEF OAM_X_OFS EQU 8  ; Add 8 to a screen X coordinate to make a sprite show up in the right spot

DEF OAM_COUNT           EQU 40  ; Total number of hardware objects the Game Boy can draw simultaneously (Max 40!)

; Moving Object Flags Bitmasks Configuration Options
DEF OAMF_PRI        EQU %10000000 ; Priority bit: 0 = Render sprite above background, 1 = Hide behind background
DEF OAMF_YFLIP      EQU %01000000 ; Flip sprite upside down vertically
DEF OAMF_XFLIP      EQU %00100000 ; Flip sprite backwards horizontally (Mirror)
DEF OAMF_PAL0       EQU %00000000 ; Apply DMG Monochrome Shading Palette Map profile index 0
DEF OAMF_PAL1       EQU %00010000 ; Apply DMG Monochrome Shading Palette Map profile index 1
DEF OAMF_BANK0      EQU %00000000 ; Pull texture assets out from native Video RAM storage bank page 0 (GBC)
DEF OAMF_BANK1      EQU %00001000 ; Pull texture assets out from secondary Video RAM storage bank page 1 (GBC)

DEF OAMF_PALMASK    EQU %00000111 ; Color Mode Palette identification filter bitmask (GBC Color selection)

; Moving Object Individual Bit Positions Indices (For target modifications via BIT/SET/RES instructions)
DEF OAMB_PRI        EQU 7
DEF OAMB_YFLIP      EQU 6
DEF OAMB_XFLIP      EQU 5
DEF OAMB_PAL1       EQU 4
DEF OAMB_BANK1      EQU 3


; ==============================================================================
; NINTENDO MASTER SECURITY CARTRIDGE BOOTSTRAP GRAPHICS BLOCK
; ==============================================================================
; This macro generates the mandatory data stream that the Game Boy looks for 
; during the scrolling boot sequence. If this is changed by even a single bit, 
; a real console will lock itself up and refuse to run your game to prevent piracy!
MACRO NINTENDO_LOGO
    DB  $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
    DB  $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
    DB  $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
ENDM


; ==============================================================================
; DEPRECATED LEGACY ADAPTER CONSTANTS REGISTERS
; ==============================================================================
; These are old, broken definitions kept only to keep super old code from breaking.
; Don't use them in new projects!
DEF IEF_LCDC       EQU %00000010 ; Obsolete variant name for IEF_STAT registers mapping masks
DEF _VRAM8000      EQU _VRAM     ; Obsolete variant tracking reference to Video RAM bank start
DEF _VRAM8800      EQU _VRAM+$800; Obsolete reference to second tier VRAM segments
DEF _VRAM9000      EQU _VRAM+$1000; Obsolete reference to final tile bank sector tiers
DEF CART_SRAM_2KB  EQU 1         ; Non-standard incomplete fractional SRAM configuration size indicator


    ENDC ; HARDWARE_INC File termination scope block finish safety check rule line