; ==============================================================================
; CONSTANTS.INC - The Game's Blueprint Settings
; ==============================================================================
; This file defines names for raw numbers so our code reads like English.

INCLUDE "hardware.inc"   ; Pulls in official Game Boy hardware register definitions

; Define game screen boundary limits using system defaults
SCREEN_WIDTH  EQU SCRN_X  ; Set SCREEN_WIDTH to 160 pixels (standard GB width)
SCREEN_HEIGHT EQU SCRN_Y  ; Set SCREEN_HEIGHT to 144 pixels (standard GB height)
BALL_SPEED    EQU 1       ; The ball will move exactly 1 pixel per frame