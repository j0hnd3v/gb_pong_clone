; ==============================================================================
; SPRITES.ASM - Shadow Sprite Engine Renderer OAM Translator
; ==============================================================================
; Maps current positioning coordinate values out to OAM system structural layouts.
; Each object entry takes up exactly 4 bytes: [Y-Pos, X-Pos, Tile-ID, Attributes].

SECTION "SpritesCode", ROM0 ; Keep sprite translation engine code in main ROM bank

UpdateSprites::
    ld hl, wShadowOAM   ; Point tracking destination to root of Local Work RAM buffer space

    ld a, [wGameState]  ; Read active game condition state tracking context properties
    and a               ; Evaluate value properties status data
    jr nz, .drawScoreOnly ; If non-zero (Game Over active), skip drawing gameplay pieces

    ; ==========================================================================
    ; --- STANDARD PLAYING STATE OBJECT GRAPHICS LAYOUT RENDERING MAPS ---
    ; ==========================================================================
    
    ; --- CONSTRUCT ENTRY OBJECT 0: SCREEN BALL GRAPHICS ---
    ld a, [wBallY]      ; Fetch vertical line coordinate data values
    ld [hli], a         ; Save to tracking buffer entry byte 0 (Y-Coord) and increment pointer
    ld a, [wBallX]      ; Fetch horizontal line coordinate data values
    ld [hli], a         ; Save to tracking buffer entry byte 1 (X-Coord) and increment pointer
    ld a, 4             ; Tile entry ID inside texture map data table (Tile 4 = Round Ball)
    ld [hli], a         ; Save to tracking buffer entry byte 2 (Tile-ID) and increment pointer
    xor a               ; Clear options bitmask parameters to 0 (No mirror, Palette 0)
    ld [hli], a         ; Save to tracking buffer entry byte 3 (Attributes) and increment pointer

    ; --- CONSTRUCT USER PLAYER PADDLE (Composite: 3 stacked 8x8 blocks = 24px) ---
    ; [Part Tier 1: Paddle Top Cap Piece Layout]
    ld a, [wPlayerY]    ; Fetch base height position reference data
    ld [hli], a         ; Store Object Y-Coordinate and step forward
    ld a, 8 + OAM_X_OFS ; Set static horizontal distance coordinate offset along left margin line
    ld [hli], a         ; Store Object X-Coordinate and step forward
    ld a, 1             ; Tile entry ID inside texture map table (Tile 1 = Top Cap)
    ld [hli], a         ; Store Object Tile-ID and step forward
    xor a               ; Clear properties parameters flags
    ld [hli], a         ; Store Object Attributes and step forward

    ; [Part Tier 2: Paddle Center Extension Piece Layout]
    ld a, [wPlayerY]    ; Fetch base height position reference data
    add 8               ; Offset vertical coordinate location down by 8 pixels to stack cleanly
    ld [hli], a         ; Store Object Y-Coordinate and step forward
    ld a, 8 + OAM_X_OFS ; Maintain horizontal alignment
    ld [hli], a         ; Store Object X-Coordinate and step forward
    ld a, 2             ; Tile entry ID inside texture map table (Tile 2 = Middle Body)
    ld [hli], a         ; Store Object Tile-ID and step forward
    xor a               ; Clear attributes parameters
    ld [hli], a         ; Store Object Attributes and step forward

    ; [Part Tier 3: Paddle Bottom Cap Piece Layout]
    ld a, [wPlayerY]    ; Fetch base height position reference data
    add 16              ; Offset vertical coordinate location down by 16 pixels to complete stack
    ld [hli], a         ; Store Object Y-Coordinate and step forward
    ld a, 8 + OAM_X_OFS ; Maintain horizontal alignment
    ld [hli], a         ; Store Object X-Coordinate and step forward
    ld a, 3             ; Tile entry ID inside texture map table (Tile 3 = Bottom Cap)
    ld [hli], a         ; Store Object Tile-ID and step forward
    xor a               ; Clear attributes parameters
    ld [hli], a         ; Store Object Attributes and step forward

    ; --- CONSTRUCT BOT COMPUTER PADDLE (Composite: 3 stacked 8x8 blocks = 24px) ---
    ; [Part Tier 1: Paddle Top Cap Piece Layout]
    ld a, [wCpuY]       ; Fetch base height position reference data
    ld [hli], a         ; Store Object Y-Coordinate and step forward
    ld a, 144 + OAM_X_OFS ; Set static horizontal distance coordinate offset along right margin line
    ld [hli], a         ; Store Object X-Coordinate and step forward
    ld a, 1             ; Tile entry ID inside texture map table (Tile 1 = Top Cap)
    ld [hli], a         ; Store Object Tile-ID and step forward
    xor a               ; Clear attributes parameters
    ld [hli], a         ; Store Object Attributes and step forward

    ; [Part Tier 2: Paddle Center Extension Piece Layout]
    ld a, [wCpuY]       ; Fetch base height position reference data
    add 8               ; Offset vertical coordinate location down by 8 pixels
    ld [hli], a         ; Store Object Y-Coordinate and step forward
    ld a, 144 + OAM_X_OFS ; Maintain horizontal alignment
    ld [hli], a         ; Store Object X-Coordinate and step forward
    ld a, 2             ; Tile entry ID inside texture map table (Tile 2 = Middle Body)
    ld [hli], a         ; Store Object Tile-ID and step forward
    xor a               ; Clear attributes parameters
    ld [hli], a         ; Store Object Attributes and step forward

    ; [Part Tier 3: Paddle Bottom Cap Piece Layout]
    ld a, [wCpuY]       ; Fetch base height position reference data
    add 16              ; Offset vertical coordinate location down by 16 pixels
    ld [hli], a         ; Store Object Y-Coordinate and step forward
    ld a, 144 + OAM_X_OFS ; Maintain horizontal alignment
    ld [hli], a         ; Store Object X-Coordinate and step forward
    ld a, 3             ; Tile entry ID inside texture map table (Tile 3 = Bottom Cap)
    ld [hli], a         ; Store Object Tile-ID and step forward
    xor a               ; Clear attributes parameters
    ld [hli], a         ; Store Object Attributes and step forward

    jr .drawScores      ; Jump down forward to map score overlay numbers data

.drawScoreOnly
    ; Wipe gameplay elements (ball/paddles) off the screen during Game Over scene
    ld c, 28            ; 7 active game objects * 4 bytes each = 28 bytes total
.loopHide
    xor a               ; Load value 0 (Setting Y-Coordinate to 0 hides a sprite off-screen)
    ld [hli], a         ; Overwrite coordinate space data with 0 and advance pointer
    dec c               ; Decrement cleaning countdown loop variable counter
    jr nz, .loopHide    ; Loop back until all 28 gameplay object bytes are safely cleared out

.drawScores
    ; ==========================================================================
    ; --- COMPOSITE USER PLAYER SCOREBOARD SYSTEM GRAPHICS RENDERING MAPS ---
    ; ==========================================================================
    ld a, [wPlayerScore] ; Fetch current numeric score tracking value
    add a, a            ; Multiply score value by 2 (Each scoreboard number spans 2 vertical tiles)
    add 5               ; Offset calculation by adding start index code of Number 0 (Tile 5)
    ld b, a             ; Stash generated numeric Tile-ID mapping code safe inside register B

    ; [Map Component: Upper Half Block Frame Structure]
    ld a, 8 + OAM_Y_OFS ; Set vertical row level position alignment coordinates
    ld [hli], a         ; Write score display Y-Coordinate position and advance pointer
    ld a, 64 + OAM_X_OFS ; Set horizontal row level position alignment coordinates
    ld [hli], a         ; Write score display X-Coordinate position and advance pointer
    ld a, b             ; Fetch stored top tile map reference pointer index value
    ld [hli], a         ; Commit calculated Tile-ID link value and advance pointer
    xor a               ; Clear options properties configuration parameters flags
    ld [hli], a         ; Commit structural attributes options data and advance pointer

    ; [Map Component: Lower Half Block Frame Structure]
    ld a, 16 + OAM_Y_OFS ; Set vertical row level position alignment coordinates directly below top
    ld [hli], a         ; Write score display Y-Coordinate position and advance pointer
    ld a, 64 + OAM_X_OFS ; Maintain exact horizontal column matching alignment coordinates
    ld [hli], a         ; Write score display X-Coordinate position and advance pointer
    ld a, b             ; Fetch top tile map reference index value data
    inc a               ; Increment tile pointer index number by 1 to target bottom tile graphic
    ld [hli], a         ; Commit calculated Tile-ID link value and advance pointer
    xor a               ; Clear options attributes flags
    ld [hli], a         ; Commit structural attributes options data and advance pointer

    ; ==========================================================================
    ; --- COMPOSITE BOT COMPUTER SCOREBOARD SYSTEM GRAPHICS RENDERING MAPS ---
    ; ==========================================================================
    ld a, [wCpuScore]   ; Fetch current numeric score tracking value
    add a, a            ; Multiply score value by 2 to account for double-height numbers
    add 5               ; Offset calculation by adding start index code of Number 0 (Tile 5)
    ld b, a             ; Stash generated numeric Tile-ID mapping code inside register B

    ; [Map Component: Upper Half Block Frame Structure]
    ld a, 8 + OAM_Y_OFS ; Set vertical row level position alignment coordinates
    ld [hli], a         ; Write score display Y-Coordinate position and advance pointer
    ld a, 88 + OAM_X_OFS ; Set horizontal row level position alignment coordinates (Right side)
    ld [hli], a         ; Write score display X-Coordinate position and advance pointer
    ld a, b             ; Fetch top tile map reference index value data
    ld [hli], a         ; Commit calculated Tile-ID link value and advance pointer
    xor a               ; Clear options attributes flags
    ld [hli], a         ; Commit structural attributes options data and advance pointer

    ; [Map Component: Lower Half Block Frame Structure]
    ld a, 16 + OAM_Y_OFS ; Set vertical row level position alignment coordinates directly below top
    ld [hli], a         ; Write score display Y-Coordinate position and advance pointer
    ld a, 88 + OAM_X_OFS ; Maintain exact horizontal column matching alignment coordinates
    ld [hli], a         ; Write score display X-Coordinate position and advance pointer
    ld a, b             ; Fetch top tile map reference index value data
    inc a               ; Increment tile pointer index number by 1 to target bottom tile graphic
    ld [hli], a         ; Commit calculated Tile-ID link value and advance pointer
    xor a               ; Clear options attributes flags
    ld [hli], a         ; Commit structural attributes options data and advance pointer

    ; --- INJECT HARD TERMINATION BOUNDARY SPACER BLOCK ---
    ; Force-clear the next empty slot to prevent sprite artifacts ("ghosting") from rendering.
    xor a               ; Load value 0
    ld [hli], a         ; Set unused sprite entry 10 Y-Position to 0 (Hides it completely)
    ld [hli], a         ; Set X-Position to 0
    ld [hli], a         ; Set Tile-ID to 0
    ld [hli], a         ; Set Attributes to 0

    ret                 ; End engine translation phase step and return safely