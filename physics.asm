; ==============================================================================
; PHYSICS.ASM - Calculated Collision & Math Physics Subsystem
; ==============================================================================

SECTION "GamePhysicsCode", ROM0 ; Store math modules inside fixed game ROM storage space

MoveBall:
    ld a, [wGameState]  ; Read current execution state system context flag
    and a               ; Check if state value is non-zero (Game Over menus active)
    ret nz              ; If state is not 0, halt update routines and exit instantly

    ; --- VERTICAL MOTION CALCULATION ROUTINES (Y-AXIS) ---
    ld a, [wDirectionY] ; Load current vertical trajectory tracking angle data
    cp 2                ; Check if set to type 2 (Perfectly flat horizontal flight)
    jr z, .xAxis        ; If traveling perfectly flat, skip vertical math equations
    
    cp 0                ; Check if set to type 0 (Ball is angled upward)
    jr nz, .moveDown    ; If not 0, jump forward to execute move down routine step
    
    ; --- Ball Traveling Upwards Engine Path ---
    ld a, [wBallY]      ; Load current ball height layout value
    dec a               ; Subtract 1 pixel from current vertical coordinate
    ld [wBallY], a      ; Save updated positioning coordinate to RAM register memory
    cp 8 + OAM_Y_OFS    ; Compare position coordinates against top ceiling boundary lines
    jr nz, .xAxis       ; If ceiling hasn't been hit, skip forward to X-axis tracking
    ld a, 1             ; Bounce! Change vertical trajectory setting to 1 (Downwards)
    ld [wDirectionY], a ; Save new directional vector inside tracking data memory
    jr .xAxis           ; Jump forward to process horizontal calculations

.moveDown
    ; --- Ball Traveling Downwards Engine Path ---
    ld a, [wBallY]      ; Load current ball height layout value
    inc a               ; Add 1 pixel to current vertical coordinate
    ld [wBallY], a      ; Save updated positioning coordinate to RAM register memory
    cp 144 + OAM_Y_OFS  ; Compare position coordinates against bottom floor boundary lines
    jr nz, .xAxis       ; If floor hasn't been hit, skip forward to X-axis tracking
    xor a               ; Bounce! Clear register A to 0 (Upwards vector trajectory code)
    ld [wDirectionY], a ; Save new directional vector inside tracking data memory

; --- HORIZONTAL MOTION CALCULATION ROUTINES (X-AXIS) ---
.xAxis
    ld a, [wDirectionX] ; Load current horizontal travel vector data tracking value
    and a               ; Check tracking state properties
    jr z, .moveLeft     ; If tracking 0, jump to process moving left towards user

    ; ==========================================================================
    ; --- BALL TRAVELING RIGHT (Heading Directly Towards Computer AI Bot) ---
    ; ==========================================================================
    ld a, [wBallX]      ; Load current ball horizontal placement location coordinate
    inc a               ; Advance position forward right by 1 pixel step
    ld [wBallX], a      ; Save updated positioning coordinate to memory registers
    
    cp 144 + OAM_X_OFS  ; Check if ball crossed into the Computer's defensive zone boundary    
    jr nz, .testPlayerPoint ; If not deep enough, skip to check if it passed out of bounds
    
    ; --- COMPUTER BOT HITBOX BOUNDARY MATHEMATICS ---
    ld a, [wCpuY]       ; Load bot top paddle baseline coordinate height limits
    ld b, a             ; Stash baseline height storage inside register B
    ld a, [wBallY]      ; Load ball current height placement location coordinate
    sub b               ; Subtract paddle top from ball height (Find relative impact offset distance)
    
    jr c, .testPlayerPoint ; If result is negative, ball passed completely above paddle cap
    cp 24               ; Check against length of paddle structure body size (24 pixels tall)
    jr nc, .testPlayerPoint ; If result is 24 or higher, ball passed completely below paddle edge
    
    ; --- COLLISION SECTION SEGMENT REFLECTION PARSER ---
    ; Divide paddle into 3 sections of 8 pixels each to calculate reflection angle offsets.
    cp 8                ; Did ball impact top segment slice tier? (Offset below 8 pixels)
    jr c, .cpuTopEdge   ; If yes, branch to handle top edge impact bounce logic
    cp 16               ; Did ball impact solid middle body tier? (Offset below 16 pixels)
    jr c, .cpuCenter    ; If yes, branch to handle dead center flat reflection logic
    
    ; --- Bottom Segment Tier Action: Reflect Upwards ---
    xor a               ; Load trajectory type code 0 (Angled Upwards)
    ld [wDirectionY], a ; Write vector to memory
    jr .invertXCpu      ; Jump to execute horizontal axis redirection sequence

.cpuTopEdge:
    ld a, 1             ; Load trajectory type code 1 (Angled Downwards)
    ld [wDirectionY], a ; Write vector to memory
    jr .invertXCpu      ; Jump to execute horizontal axis redirection sequence

.cpuCenter:
    ld a, 2             ; Load trajectory type code 2 (Perfectly Straight Horizontal Line)
    ld [wDirectionY], a ; Write vector to memory

.invertXCpu:
    xor a               ; Clear accumulator A to zero
    ld [wDirectionX], a ; Set direction tracking vector state to 0 (Reflect travel heading Left)
    ret                 ; Complete loop pass step and exit processing

.testPlayerPoint
    ld a, [wBallX]      ; Load ball horizontal position coordinate
    cp 160 + OAM_X_OFS  ; Check if ball went entirely past the right edge of screen bounds
    jr nz, .endXAxis    ; If not out of bounds, skip to end horizontal processing steps
    
    ld a, [wPlayerScore] ; Load User's current score value data tally
    inc a               ; Increment value data point tracking by 1
    ld [wPlayerScore], a ; Save user's updated point score out to RAM variables
    cp 9                ; Check if player has reached the max match score limit of 9 points
    jr nz, .resetBall   ; If score is below 9, reset ball to center for next round
    
    ld a, 1             ; Set match mode flag active state to 1
    ld [wGameState], a  ; Put engine into game over state tracking mode
    call DrawYouWin     ; Render User Victory text layout graphics onto background map screens
    ret                 ; Return from update phase loop

    ; ==========================================================================
    ; --- BALL TRAVELING LEFT (Heading Directly Towards User Player Paddle) ---
    ; ==========================================================================
.moveLeft
    ld a, [wBallX]      ; Load current ball horizontal placement location coordinate
    dec a               ; Retract position back left by 1 pixel step
    ld [wBallX], a      ; Save updated positioning coordinate to memory registers
    
    cp 8 + OAM_X_OFS    ; Check if ball crossed into User's defensive zone boundary line
    jr nz, .testCpuPoint ; If not deep enough, skip forward to check if it passed out of bounds
    
    ; --- USER PLAYER HITBOX BOUNDARY MATHEMATICS ---
    ld a, [wPlayerY]    ; Load player paddle top baseline coordinate height limits
    ld b, a             ; Stash baseline height storage inside register B
    ld a, [wBallY]      ; Load ball current height placement location coordinate
    sub b               ; Subtract paddle top from ball height (Find relative impact offset distance)
    
    jr c, .testCpuPoint ; If result is negative, ball passed completely above paddle cap
    cp 24               ; Check against length of paddle structure body size (24 pixels tall)
    jr nc, .testCpuPoint ; If result is 24 or higher, ball passed completely below paddle edge
    
    ; --- COLLISION SECTION SEGMENT REFLECTION PARSER ---
    cp 8                ; Did ball impact top segment slice tier? (Offset below 8 pixels)
    jr c, .playerTopEdge ; If yes, branch to handle top edge impact bounce logic
    cp 16               ; Did ball impact solid middle body tier? (Offset below 16 pixels)
    jr c, .playerCenter ; If yes, branch to handle dead center flat reflection logic
    
    ; --- Bottom Segment Tier Action: Reflect Upwards ---
    xor a               ; Load trajectory type code 0 (Angled Upwards)
    ld [wDirectionY], a ; Write vector to memory
    jr .invertXPlayer   ; Jump to execute horizontal axis redirection sequence

.playerTopEdge:
    ld a, 1             ; Load trajectory type code 1 (Angled Downwards)
    ld [wDirectionY], a ; Write vector to memory
    jr .invertXPlayer   ; Jump to execute horizontal axis redirection sequence

.playerCenter:
    ld a, 2             ; Load trajectory type code 2 (Perfectly Straight Horizontal Line)
    ld [wDirectionY], a ; Write vector to memory

.invertXPlayer:
    ld a, 1             ; Load horizontal vector code 1
    ld [wDirectionX], a ; Set direction tracking vector state to 1 (Reflect travel heading Right)
    ret                 ; Complete loop pass step and exit processing

.testCpuPoint
    ld a, [wBallX]      ; Load ball horizontal position coordinate
    cp 0                ; Check if ball went entirely past the left edge of screen bounds
    jr nz, .endXAxis    ; If not out of bounds, skip to end horizontal processing steps
    
    ld a, [wCpuScore]   ; Load Computer Bot's current score value data tally
    inc a               ; Increment value data point tracking by 1
    ld [wCpuScore], a   ; Save computer's updated point score out to RAM variables
    cp 9                ; Check if bot has reached the max match score limit of 9 points
    jr nz, .resetBall   ; If score is below 9, reset ball to center for next round
    
    ld a, 1             ; Set match mode flag active state to 1
    ld [wGameState], a  ; Put engine into game over state tracking mode
    call DrawYouLose    ; Render Bot Defeat text layout graphics onto background map screens
    ret                 ; Return from update phase loop

.resetBall
    ld a, 80 + OAM_X_OFS ; Set horizontal coordinate center target tracking alignment
    ld [wBallX], a      ; Write default location coordinates to ball horizontal RAM registers
    ld a, 64 + OAM_Y_OFS ; Set vertical coordinate center target tracking alignment
    ld [wBallY], a      ; Write default location coordinates to ball vertical RAM registers
    ld a, 2             ; Load type 2 trajectory tracking parameters
    ld [wDirectionY], a ; Force flat horizontal travel velocity on reset
.endXAxis
    ret                 ; Done with execution pass cycle steps

; ==============================================================================
; ARTIFICIAL INTELLIGENCE COMPUTER BOT ENGINE LOGIC MODULE
; ==============================================================================
IA_Cpu:
    ld a, [wGameState]  ; Read game status mode flag properties
    and a               ; Evaluate properties value
    ret nz              ; If non-zero (Game Over), skip executing bot processing calculations                       

    ; Create unpredictability by adding reaction lag using the internal hardware clock
    ldh a, [rDIV]       ; Read hardware register DIV timer (Changes constantly at 16384Hz)
    and %00000011       ; Isolate the lowest two bits to get a number between 0 and 3
    
    ; Distribute behavioral routines across lag step tiers
    cp 0                ; Evaluate equality state to zero
    jr z, .aimCenter    ; Branch to seek paddle center calculations
    cp 1                ; Evaluate equality state to one
    jr z, .aimTop       ; Branch to seek paddle top calculations
    cp 2                ; Evaluate equality state to two
    jr z, .aimBottom    ; Branch to seek paddle bottom calculations
    
    ; Reaction logic base vectors based on ball trajectory profile directions
    ld a, [wDirectionY] ; Load active vertical vector calculations tracking details
    cp 0                ; Is ball traveling up?
    jr z, .ballMovingUp ; Branch to execute predictive lead steps upwards
    cp 1                ; Is ball traveling down?
    jr z, .ballMovingDown ; Branch to execute predictive lead steps downwards

.aimCenter
    ld h, 8             ; Target tracking height midpoint line alignment zone (8 pixel center offset)
    jr .applyAIM        ; Pass calculations forward to apply step filters

.aimTop
    ld h, 0             ; Target tracking height top edge cap alignment zone (0 pixel offset)
    jr .applyAIM        ; Pass calculations forward to apply step filters

.aimBottom
    ld h, 16            ; Target tracking height lower edge cap alignment zone (16 pixel offset)
    jr .applyAIM        ; Pass calculations forward to apply step filters

.ballMovingUp
    ld h, 4             ; Intercept lead calculation scale tier factor adjustment values (4 pixel offset)
    jr .applyAIM        ; Pass calculations forward to apply step filters

.ballMovingDown
    ld h, 12            ; Intercept lead calculation scale tier factor adjustment values (12 pixel offset)

.applyAIM
    ld a, [wBallY]      ; Load current ball height layout value location
    ld b, a             ; Stash baseline height storage value inside register B
    ld a, [wCpuY]       ; Load computer paddle height coordinate placement value
    add h               ; Add target offset distance factor modifier calculations
    cp b                ; Compare calculated tracking point against raw ball coordinates
    jr z, .IACpuEnd     ; If values perfectly match, stand perfectly still and exit
    jr c, .IACpuMoveDown ; If lower, jump to execute descending track motions

    ; --- Move Computer Bot Paddle Upward ---
    ld a, [wCpuY]       ; Load height location value data fields
    dec a               ; Subtract 1 pixel from spatial coordinate levels
    ld [wCpuY], a       ; Save modification back to computer tracking memory variables
    ret                 ; Done with pass step calculation loop
.IACpuMoveDown
    ; --- Move Computer Bot Paddle Downward ---
    ld a, [wCpuY]       ; Load height location value data fields
    inc a               ; Add 1 pixel to spatial coordinate fields
    ld [wCpuY], a       ; Save modification back to computer tracking memory variables
.IACpuEnd
    ret                 ; Done with execution tracking block steps