; ==============================================================================
; GRAPHICS.ASM - Raw Asset Bitmap Data Bank
; ==============================================================================
; This section contains the literal pixel art for our sprites and text fonts.
; Each tile is 8x8 pixels. In Game Boy 2BPP (2 bits per pixel) format, every
; single row of 8 pixels takes up exactly 2 bytes of memory.

SECTION "GraphicsData", ROM0 ; Store this data in the main, read-only ROM block

GraphicsData::

.tileEmpty ; Tile ID 0: Used to wipe graphics off the background screen
    db $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00

.spritePaddleTop ; Tile ID 1: The rounded top cap of our Pong paddle
    db $3C, $3C, $7E, $7E, $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

.spritePaddleMiddle ; Tile ID 2: The solid middle extension body of our paddle
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

.spritePaddleBottom ; Tile ID 3: The rounded bottom cap of our Pong paddle
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF, $7E, $7E, $3C, $3C

.spriteBallRound ; Tile ID 4: A perfectly round ball asset
    db $3C, $3C, $7E, $7E, $FF, $FF, $FF, $FF
    db $FF, $FF, $FF, $FF, $7E, $7E, $3C, $3C

; ==============================================================================
; SCOREBOARD ALPHANUMERICS (16-Pixels Tall: Built using pairs of 8x8 tiles)
; ==============================================================================

.num0_Top      ; Tile ID 5: Upper half of '0'
    db $7E, $7E, $FF, $FF, $C3, $C3, $C3, $C3
    db $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
.num0_Bottom   ; Tile ID 6: Lower half of '0'
    db $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    db $C3, $C3, $C3, $C3, $FF, $FF, $7E, $7E

.num1_Top      ; Tile ID 7: Upper half of '1'
    db $18, $18, $38, $38, $F8, $F8, $18, $18
    db $18, $18, $18, $18, $18, $18, $18, $18
.num1_Bottom   ; Tile ID 8: Lower half of '1'
    db $18, $18, $18, $18, $18, $18, $18, $18
    db $18, $18, $18, $18, $FF, $FF, $FF, $FF

.num2_Top      ; Tile ID 9: Upper half of '2'
    db $7E, $7E, $FF, $FF, $C3, $C3, $03, $03
    db $0F, $0F, $3F, $3F, $FC, $FC, $F0, $F0
.num2_Bottom   ; Tile ID 10: Lower half of '2'
    db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
    db $C3, $C3, $C3, $C3, $FF, $FF, $FF, $FF

.num3_Top      ; Tile ID 11: Upper half of '3'
    db $7E, $7E, $FF, $FF, $C3, $C3, $03, $03
    db $1F, $1F, $1F, $1F, $03, $03, $03, $03
.num3_Bottom   ; Tile ID 12: Lower half of '3'
    db $03, $03, $03, $03, $03, $03, $C3, $C3
    db $C3, $C3, $FF, $FF, $7E, $7E, $00, $00

.num4_Top      ; Tile ID 13: Upper half of '4'
    db $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    db $FF, $FF, $FF, $FF, $03, $03, $03, $03
.num4_Bottom   ; Tile ID 14: Lower half of '4'
    db $03, $03, $03, $03, $03, $03, $03, $03
    db $03, $03, $03, $03, $03, $03, $03, $03

.num5_Top      ; Tile ID 15: Upper half of '5'
    db $FF, $FF, $FF, $FF, $C0, $C0, $FC, $FC
    db $FE, $FE, $03, $03, $03, $03, $03, $03
.num5_Bottom   ; Tile ID 16: Lower half of '5'
    db $03, $03, $03, $03, $03, $03, $C3, $C3
    db $C3, $C3, $FF, $FF, $7E, $7E, $00, $00

.num6_Top      ; Tile ID 17: Upper half of '6'
    db $7E, $7E, $FF, $FF, $C0, $C0, $FC, $FC
    db $FE, $FE, $C3, $C3, $C3, $C3, $C3, $C3
.num6_Bottom   ; Tile ID 18: Lower half of '6'
    db $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    db $C3, $C3, $C3, $C3, $FF, $FF, $7E, $7E

.num7_Top      ; Tile ID 19: Upper half of '7'
    db $FF, $FF, $FF, $FF, $C3, $C3, $03, $03
    db $06, $06, $0C, $0C, $18, $18, $18, $18
.num7_Bottom   ; Tile ID 20: Lower half of '7'
    db $30, $30, $30, $30, $60, $60, $60, $60
    db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0

.num8_Top      ; Tile ID 21: Upper half of '8'
    db $7E, $7E, $FF, $FF, $C3, $C3, $C3, $C3
    db $7E, $7E, $7E, $7E, $C3, $C3, $C3, $C3
.num8_Bottom   ; Tile ID 22: Lower half of '8'
    db $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    db $C3, $C3, $C3, $C3, $FF, $FF, $7E, $7E

.num9_Top      ; Tile ID 23: Upper half of '9'
    db $7E, $7E, $FF, $FF, $C3, $C3, $C3, $C3
    db $FF, $FF, $7E, $7E, $03, $03, $03, $03
.num9_Bottom   ; Tile ID 24: Lower half of '9'
    db $03, $03, $03, $03, $03, $03, $03, $03
    db $03, $03, $03, $03, $FF, $FF, $7E, $7E
    
; ==============================================================================
; ALPHABET TILE ENGINE STORAGE (Standard Text Characters)
; ==============================================================================

.tile_Y  ; Tile ID 25
    db $C3, $C3, $C3, $C3, $66, $66, $3C, $3C, $18, $18, $18, $18, $18, $18, $18, $18
.tile_O  ; Tile ID 26
    db $3C, $3C, $66, $66, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $66, $66, $3C, $3C
.tile_U  ; Tile ID 27
    db $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $66, $66, $3C, $3C
.tile_W  ; Tile ID 28
    db $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $DB, $DB, $FF, $FF, $E7, $E7, $C3, $C3
.tile_I  ; Tile ID 29
    db $7E, $7E, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $7E, $7E
.tile_N  ; Tile ID 30
    db $C3, $C3, $E3, $E3, $F3, $F3, $DB, $DB, $CF, $CF, $DF, $DF, $C7, $C7, $C3, $C3
.tile_L  ; Tile ID 31
    db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $FF, $FF, $FF, $FF
.tile_S  ; Tile ID 32
    db $3E, $3E, $63, $63, $60, $60, $3C, $3C, $07, $07, $03, $03, $63, $63, $7C, $7C
.tile_E  ; Tile ID 33
    db $FF, $FF, $C0, $C0, $C0, $C0, $FC, $FC, $FC, $FC, $C0, $C0, $FF, $FF, $FF, $FF
.tile_P  ; Tile ID 34
    db $FC, $FC, $C6, $C6, $C6, $C6, $FC, $FC, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
.tile_R  ; Tile ID 35
    db $FC, $FC, $C6, $C6, $C6, $C6, $FC, $FC, $DE, $DE, $CC, $CC, $C6, $C6, $C6, $C6
.tile_A  ; Tile ID 36
    db $3C, $3C, $66, $66, $C6, $C6, $FF, $FF, $C6, $C6, $C6, $C6, $C6, $C6, $C6, $C6
.tile_T  ; Tile ID 37
    db $FF, $FF, $FF, $FF, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18

GraphicsDataEnd:: ; End marker to help calculate exact data size dynamically