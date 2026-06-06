INCLUDE "constants.inc"

; ==============================================================================
; WRAM VARIABLE SYSTEM DEFINITIONS (Work RAM Memory Layout)
; ==============================================================================
SECTION "GameVariables", WRAM0 ; Put these inside general onboard system RAM

wShadowOAM:      ds sizeof_OAM_ATTRS * OAM_COUNT ; Local copy of sprite table (160 bytes)
wFrameReady:     db ; Global frame synchronizer flag (0 = waiting, 1 = render!)
wTimeCounter:    db ; General purpose frame timer counter variable
wGameState:      db ; Controls screens: 0 = Main active gameplay, 1 = Match Over screen
wBallX:          db ; Current Horizontal tracking position of our ping-pong ball
wBallY:          db ; Current Vertical tracking position of our ping-pong ball
wDirectionX:     db ; Traveling horizontal direction vectors: 0 = Going Left, 1 = Right
wDirectionY:     db ; Vertical travel state vectors: 0 = Up, 1 = Down, 2 = Flat Horizontal
wPlayerY:        db ; Left-hand Player paddle absolute screen height
wCpuY:           db ; Right-hand Computer bot paddle absolute screen height
wPlayerScore:    db ; Accumulator for User's point score tally (Cap at 9)
wCpuScore:       db ; Accumulator for Computer AI's point score tally (Cap at 9)

; ==============================================================================
; HRAM VARIABLE SYSTEM DEFINITIONS (High-Speed RAM Region)
; ==============================================================================
SECTION "HRAMVariables", HRAM ; Put this inside the fast 127-byte zero page space

hExecuteDMA:     ds 10 ; Allocates room to run the fast OAM Sprite DMA transfer loop

; ==============================================================================
; SYSTEM INTERRUPT VECTOR ENGINE SETUP
; ==============================================================================
SECTION "VBlankInterrupt", ROM0[$0040] ; Hardwired hardware address for screen refresh
    push af             ; Protect current Accumulator value by pushing to Stack
    ld a, 1             ; Set our variable flag high
    ld [wFrameReady], a ; Tell the game loop that the hardware just finished a frame draw
    pop af              ; Restore original accumulator context state back safely
    reti                ; Return from interrupt and re-enable global interrupt engine

; ==============================================================================
; GAME BOY FIRMWARE BOOT ROM CARTRIDGE HEADER
; ==============================================================================
SECTION "Header", ROM0[$0100] ; Game Boy processor boots up exactly right here
    nop                 ; Standard initial spacer operation
    jp Start            ; Jump straight past header properties into main code engine

    NINTENDO_LOGO       ; Automatically generates standard raw Nintendo validation logo
    db "PONG RGBDS     " ; Game project title string (Must be padded to 15 characters)
    db CART_COMPATIBLE_DMG ; Mark cartridge to boot in classic retro monochrome mode
    db 0, 0             ; Dummy internal license placeholders
    db CART_INDICATOR_GB ; Mark hardware targeting standard Game Boy consoles
    db CART_ROM         ; Specify base ROM configuration without external extra hardware chips
    db CART_ROM_32KB    ; Set total standard size space of project data to 32 Kilobytes
    db CART_SRAM_NONE   ; Inform console there is no save file chip inside
    db CART_DEST_NON_JAPANESE ; Set international distribution region flag
    db $33              ; Define newer modern publisher code ID markers
    db $00              ; Revision tracking version value 0
    db $00              ; Header validation checksum buffer placeholder
    dw $0000            ; Global system validation checksum block buffer

; ==============================================================================
; COLD BOOT HARDWARE SETUP
; ==============================================================================
Start:
    di                  ; Disable interrupts while resetting the system registers
    ld sp, $FFFE        ; Set stack pointer register to top of safe memory space

    call DisableLCD     ; Safely turn screen off so we can modify engine data safely

    xor a               ; Quick way to clear register A to zero
    ldh [rIF], a        ; Clear pending interrupt requests register flags

    ld a, IEF_VBLANK    ; Load the precise bitmask flag for vertical blank triggers
    ldh [rIE], a        ; Store into Interrupt Enable so system notices screen updates
    ei                  ; Fire up global processing interrupts back online

    ; 1. Move DMA Loop code down directly into High-Speed HRAM memory
    ld hl, hExecuteDMA  ; Set destination pointer target address inside HRAM
    ld de, DMARoutineCode ; Set origin source data tracking line location inside ROM
    ld bc, DMARoutineCodeEnd - DMARoutineCode ; Calculate size of the loop code
    call CopyMemory     ; Execute structural data relocation loop block

    ; 2. Scrub background layout screen map spaces clean ($9800 to $9FFF)
    ld hl, $9800        ; Set tracking point to start of background layout block
    ld b, 8             ; Prepare outer index loop to process 8 solid pages
    xor a               ; Clear A to 0 (Tile index number 0 is completely empty)
.loopClearBgOuter
    ld c, 0             ; Prepare inner loop block to scale 256 byte steps
.loopClearBgInner
    ld [hli], a         ; Fill memory slot with 0 and increment index tracker pointer
    dec c               ; Step down inner loops row count
    jr nz, .loopClearBgInner ; Loop back inside if row values are remaining
    dec b               ; Step down outer page layout count index
    jr nz, .loopClearBgOuter ; Loop back if screen quadrants are incomplete

    ; 3. Upload text fonts and player tile bitmaps up to VRAM bank
    ld hl, _VRAM        ; Point to root starting point of hardware VRAM memory
    ld de, GraphicsData ; Target our source graphics asset library bank
    ld bc, GraphicsDataEnd - GraphicsData ; Find actual byte size of raw textures
    call CopyMemory     ; Transfer raw artwork data packages into target system memory

    ; 4. Clear Sprite Table (OAM)
    call ClearShadowOAM ; Erase active garbage data artifacts out of sprite shadow buffer

    ; --- Set Up Initial Variable States ---
    xor a               ; Clear accumulator to 0
    ld [wPlayerScore], a ; Reset player scoreboard tally to zero
    ld [wCpuScore], a   ; Reset computer bot score tracking tally to zero
    ld [wGameState], a  ; Boot directly into normal gameplay loop mode (0)
    ld [wDirectionX], a ; Set ball horizontal vector heading left towards player
    ld a, 2             ; Load code for straight horizontal vector path
    ld [wDirectionY], a ; Lock ball movement to flat trajectory layout vectors

    ; Base start heights for left/right game paddles
    ld a, 56 + OAM_Y_OFS ; Center top offset position value
    ld [wPlayerY], a    ; Initialize player height placement setup
    ld [wCpuY], a       ; Synchronize computer bot height configuration tracking
    
    ; Center the ball vertically relative to paddles
    ld a, 64 + OAM_Y_OFS ; Set baseline screen vertical positioning point             
    ld [wBallY], a      ; Establish ball start level height position
    
    ld a, 80 + OAM_X_OFS ; Set baseline horizontal mid-screen alignment marker
    ld [wBallX], a      ; Set ball start lateral position

    ; Define master color palettes for shades of gray
    ld a, %11100100     ; Standard palette: Black, Dark Gray, Light Gray, White
    ldh [rBGP], a       ; Save configuration inside Background palette register
    ldh [rOBP0], a      ; Save matching config inside Object Sprite palette 0 register

    ; Fire up standard LCD settings
    ld a, %10010011     ; Turn on LCD screen, backgrounds, and sprites
    ldh [rLCDC], a      ; Write setup bitmask inside Master Hardware LCD Screen Control

; ==============================================================================
; MAIN MASTER CORE GAME ENGINE LOOP
; ==============================================================================
GameLoop:
    xor a               ; Clear A to 0
    ld [wFrameReady], a ; Reset the frame sync variable to zero
.waitFrame
    halt                ; Put CPU to sleep until hardware fires VBlank interrupt
    ld a, [wFrameReady] ; Read our frame sync variable flag
    and a               ; Check if it changed to 1
    jr z, .waitFrame    ; If still 0, keep waiting for the next interrupt frame tick

    call hExecuteDMA    ; Trigger DMA update to copy shadow buffer variables to real OAM

    call ReadJoypad     ; Parse hardware d-pad inputs from player
    call MoveBall       ; Calculate physics step equations (physics.asm)
    call IA_Cpu         ; Compute Computer bot path movements (physics.asm)
    call UpdateSprites  ; Re-align graphic coordinates inside shadow OAM buffer

    jr GameLoop         ; Infinite loop back to process next frame sequence

; ==============================================================================
; USER INPUT CONTROLLER PROCESSOR
; ==============================================================================
ReadJoypad:
    ld a, %00100000     ; Select bitmask targeting D-Pad direction cross checks   
    ldh [rP1], a        ; Output command wire query out to Controller Register port
    ldh a, [rP1]        ; Read results out of controller lines
    ldh a, [rP1]        ; Read twice to allow raw hardware signals to stabilize          
    nop                 ; Microsecond timing spacer padding
    nop                 ; Microsecond timing spacer padding
    cpl                 ; Invert values (Inputs are low active; cpl makes them high active)   
    and %00001111       ; Isolate low bits (Down, Up, Left, Right directional data)     
    ld b, a             ; Stash direction state results safe inside register B                 

    ld a, %00010000     ; Select bitmask targeting system face button inputs   
    ldh [rP1], a        ; Send command wire query out to Controller register port
    ldh a, [rP1]        ; Read raw button responses
    ldh a, [rP1]        ; Read twice to settle line noise issues
    nop                 ; Timing spacer padding
    nop                 ; Timing spacer padding
    cpl                 ; Invert buttons matrix bits high active
    and %00001111       ; Isolate low bits (Start, Select, B, A action button data)
    ld c, a             ; Stash action button state results inside register C                 

    ld a, %00110000     ; Load system command line bitmask to unselect pads
    ldh [rP1], a        ; Send matrix shutdown command to reset hardware pins

    ld a, [wGameState]  ; Check current core execution mode context
    and a               ; Evaluate state value
    jr z, .gameModeActive ; If 0, jump to standard active gameplay controls

    ; --- Game Over Menu Scene Button Checks ---
    bit 3, c            ; Check if Start button is pressed
    jr z, .exitJoypad   ; If not pressed, skip out and do nothing
    
    call ClearBgText    ; Wipe out textual overlays from background display
    call ClearShadowOAM ; Wipe game objects out of shadow OAM buffer memory
    
    ; Reset scores and state variables
    xor a               ; Clear register A to 0
    ld [wPlayerScore], a ; Clear player score accumulator
    ld [wCpuScore], a   ; Clear bot score accumulator
    ld [wGameState], a  ; Reset mode flag back to standard play mode state (0)
    ld [wDirectionX], a ; Set ball to start moving left toward user
    
    ld a, 2             ; Set flat straight horizontal angle vector
    ld [wDirectionY], a ; Store trajectory type inside vertical tracking registers
    
    ld a, 80 + OAM_X_OFS ; Set ball mid-screen horizontally
    ld [wBallX], a      ; Commit horizontal start coordinates
    
    ld a, 64 + OAM_Y_OFS ; Set ball mid-screen vertically
    ld [wBallY], a      ; Commit vertical start coordinates
    
    call UpdateSprites  ; Refresh spatial alignments immediately inside shadow OAM
    call hExecuteDMA    ; Trigger flash update transfer out to hardware OAM registers
    jr .exitJoypad      ; Jump to exit parsing engine

.gameModeActive
    ; --- Normal In-Game Up / Down Paddling Control Logic ---
    bit 2, b            ; Check if Up on D-Pad is pressed
    jr z, .testDown     ; If not pressed, skip down to check Down inputs     
    
    ld a, [wPlayerY]    ; Load current height coordinate position value
    sub 2               ; Move upward by subtracting 2 pixels from coordinate
    cp 16               ; Check boundary limits against top margin ceiling
    jr nc, .saveTop     ; If above ceiling line limits, pass safely
    ld a, 16            ; Clamp position to ceiling limit value
.saveTop
    ld [wPlayerY], a    ; Save updated position back to variable

.testDown
    bit 3, b            ; Check if Down on D-Pad is pressed
    jr z, .exitJoypad   ; If not, skip button parser entirely      
    
    ld a, [wPlayerY]    ; Load current height coordinate position value
    add 2               ; Move downward by adding 2 pixels to coordinate
    cp 136              ; Check boundary limits against screen floor
    jr c, .saveBottom   ; If below floor line limits, pass safely
    ld a, 136           ; Clamp position to lowest floor limit value
.saveBottom
    ld [wPlayerY], a    ; Save updated position back to variable

.exitJoypad
    ret                 ; Return from system control parser routine

; ==============================================================================
; USER TEXT INTERFACE GRAPHICS MANAGEMENT UTILITIES
; ==============================================================================

DrawYouWin::
    call WaitVBlank     ; Wait until VBlank starts to modify text safely
    ld hl, $9926        ; Point to tile index memory coordinates on background map
    ld a, 25            ; Tile index number for letter 'Y'
    ld [hli], a         ; Write to screen map index and step to next character
    ld a, 26            ; Tile index number for letter 'O'
    ld [hli], a         ; Write character
    ld a, 27            ; Tile index number for letter 'U'
    ld [hli], a         ; Write character
    ld a, 0             ; Tile index number for completely blank empty space
    ld [hli], a         ; Write character
    ld a, 28            ; Tile index number for letter 'W'
    ld [hli], a         ; Write character
    ld a, 29            ; Tile index number for letter 'I'
    ld [hli], a         ; Write character
    ld a, 30            ; Tile index number for letter 'N'
    ld [hli], a         ; Write character
    
    call DrawPressStart ; Draw menu instructions below text line
    ret                 ; Return

DrawYouLose::
    call WaitVBlank     ; Wait until VBlank starts to modify text safely
    ld hl, $9924        ; Point to central coordinate location inside background tile map
    ld a, 25            ; Tile index number for letter 'Y'
    ld [hli], a         ; Write character
    ld a, 26            ; Tile index number for letter 'O'
    ld [hli], a         ; Write character
    ld a, 27            ; Tile index number for letter 'U'
    ld [hli], a         ; Write character
    ld a, 0             ; Tile index number for space
    ld [hli], a         ; Write character
    ld a, 31            ; Tile index number for letter 'L'
    ld [hli], a         ; Write character
    ld a, 26            ; Tile index number for letter 'O'
    ld [hli], a         ; Write character
    ld a, 32            ; Tile index number for letter 'S'
    ld [hli], a         ; Write character
    ld a, 33            ; Tile index number for letter 'E'
    ld [hli], a         ; Write character
    
    call DrawPressStart ; Draw menu instructions below text line
    ret                 ; Return

DrawPressStart:
    ld hl, $9963        ; Target a row slightly below the victory text lines
    ld a, 34            ; 'P'
    ld [hli], a         ; Write character
    ld a, 35            ; 'R'
    ld [hli], a         ; Write character
    ld a, 33            ; 'E'
    ld [hli], a         ; Write character
    ld a, 32            ; 'S'
    ld [hli], a         ; Write character
    ld a, 32            ; 'S'
    ld [hli], a         ; Write character
    ld a, 0             ; Space
    ld [hli], a         ; Write character
    ld a, 32            ; 'S'
    ld [hli], a         ; Write character
    ld a, 37            ; 'T'
    ld [hli], a         ; Write character
    ld a, 36            ; 'A'
    ld [hli], a         ; Write character
    ld a, 35            ; 'R'
    ld [hli], a         ; Write character
    ld a, 37            ; 'T'
    ld [hli], a         ; Write character
    ret                 ; Return

ClearBgText:
    call WaitVBlank     ; Wait for VBlank before updating tiles to avoid screen artifacts
    ld hl, $9920        ; Start point at top column of our target text zone box
    ld c, 80            ; Erase 80 continuous background layout tile blocks
    xor a               ; Load tile index number 0 (completely empty transparent tile)
.loopClearText
    ld [hli], a         ; Write tile index 0 into current map space and step forward
    dec c               ; Decrement loop text cell tracker counts
    jr nz, .loopClearText ; Loop back until all 80 display columns are blank
    ret                 ; Return

WaitVBlank:
    ldh a, [rLY]        ; Direct poll raw vertical line drawing status register counter
    cp 144              ; Compare lines counts against start of frame drawing limit
    jr c, WaitVBlank    ; If value is below 144, continue looping until VBlank starts
    ret                 ; Return safely

; ==============================================================================
; SUBSYSTEM CODE MODULE INCLUSIONS
; ==============================================================================
SECTION "AuxiliaryModules", ROM0
INCLUDE "video.asm"     ; Include core hardware screen setup code modules
INCLUDE "sprites.asm"   ; Include game object shadow rendering code engines
INCLUDE "physics.asm"   ; Include gameplay logic and math collision equations

SECTION "CustomGraphicsData", ROM0
INCLUDE "graphics.asm"  ; Embed raw pixel asset bank binary data inside project