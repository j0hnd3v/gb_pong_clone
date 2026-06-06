; ==============================================================================
; VIDEO.ASM - Direct Hardware Low-Level Memory Interface Controllers
; ==============================================================================

DisableLCD::
    ld a, [rLCDC]       ; Read raw master structural configurations settings flags
    bit LCDCB_ON, a     ; Check state behavior status of bit 7 (Is screen turned on?)
    ret z               ; If bit is 0, screen is already disabled; exit routine safely

.waitVBlank
    ld a, [rLY]         ; Read hardware rendering electron beam scanning line counter
    cp 144              ; Check line index coordinates against start of VBlank phase
    jr c, .waitVBlank   ; If value is below 144, keep looping until safe screen refresh time

    xor a               ; Clear register A to 0
    ld [rLCDC], a       ; Write 0 directly into hardware register LCDC to shut down screen safely
    ret                 ; Return

CopyMemory::
    ld a, [de]          ; Read single data package byte out from source tracker address
    ld [hli], a         ; Save data into target VRAM address map space, then advance pointer
    inc de              ; Step forward source track address pointer address location
    dec bc              ; Decrease structural sizing register loop tracking counter
    ld a, b             ; Load sizing high byte registry elements
    or c                ; Check if high byte and low byte counters have both reached zero
    jr nz, CopyMemory   ; If remaining bytes are left to copy, loop back to process next byte
    ret                 ; Return

ClearShadowOAM::
    ld hl, wShadowOAM   ; Point directly to root start location address of local RAM buffer table
    ld bc, sizeof_OAM_ATTRS * OAM_COUNT ; Load size of entire 160 byte OAM memory map matrix
    xor a               ; Clear register A to 0
.loop
    ld [hli], a         ; Wipe out current memory byte location data slot, then advance pointer
    dec bc              ; Decrement sizing matrix countdown tracker index loops
    ld a, b             ; Load sizing tracking components
    or c                ; Evaluate remaining matrix sizes status data field ranges
    jr nz, .loop        ; Loop back until all 160 memory array data blocks are zeroed out
    ret                 ; Return

; ==============================================================================
; HIGH SPEED OAM HARDWARE DMA BLOCK TRANSFER ENGINE ROUTINE
; ==============================================================================
; This code loop flashes our entire 160-byte shadow RAM buffer table directly into
; the internal Sprite OAM hardware registers in a split microsecond. Since it takes
; over the system bus, it MUST run from inside high-speed HRAM memory.

DMARoutineCode::
    ld a, HIGH(wShadowOAM) ; Fetch high-byte address mapping origin location of shadow table ($C0)
    ldh [rDMA], a       ; Fire value into hardware DMA register to start fast transfer copy loops
    ld a, 40            ; Load delay timer loop variable to match exact speed of transfer
.wait
    dec a               ; Step down loop timer tracking countdown
    jr nz, .wait        ; Wait 160 clock cycles for hardware data pipes to finish transfer
    ret                 ; Complete process routine step pass and return safely
DMARoutineCodeEnd::     ; End boundary marker to calculate size of routine bytes