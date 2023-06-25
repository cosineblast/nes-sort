.include "PPU.s"

.segment "HEADER"
    .byte $4E, $45, $53, $1A    ; Header
    .byte 2                     ; 16kb PRG blocks
    .byte 1                     ; 8kb CHR blocks
    .byte $01, $00              ; mapper 0, vertical mirroring

.segment "STARTUP"
.segment "VECTORS"
    ;; NMI Handler, Reset Handler, IRQ Handler
    .addr on_nmi
    .addr on_reset
    .addr 0

.segment "ZEROPAGE"

  ;; Array of 2*RENDER_COLUMN_HEIGHT (60) bytes containing the tiles for the two
  ;; columns that will be rendered on the next frame.
  ;; first 30 elements represent the first column,
  ;; last 30  elements represet the second column.
  ;; $ff - 60
  render_columns = $c3

.segment "ABS_VARS": absolute

  ;; bool, whether the program is currently runnning update code or not.
  ;; 0 if an update is not running (and it is ok for a render to run).
  ;; 1 if update code is/should be running,
  is_updating = $0200

  ;; 0 when the program is doing the initial render of the tiles
  ;; 1 when the program is already rendering the algorithm steps
  ;; 2 when the program is done with the algorithm
  sorting_stage = $0201

  SORTING_STAGE_INIT = 0
  SORTING_STAGE_SORT = 1
  SORTING_STAGE_DONE = 2


  ;; The rng_seed for the random number generation
  ;; Two bytes
  rng_seed = $0202

  ;; The on-screen indexes of the columns that must be rendered
  ;; -1 means don't render anything
  ;; Two bytes, two numbers
  render_columns_positions = $0204

  NO_RENDER_COLUMN = $ff

  ;; Initial Stage Specific:

  ;; The index of the next two elements to process
  init_stage_index = $0206


  ;; The numbers to be sorted
  ;; 128 bytes
  sorting_array = $0300

  SORTING_DATA_SIZE = 127

  RENDER_COLUMN_HEIGHT = 30

  COLUMNS_PER_SCREEN = 32


.segment "CODE"

  .import rng
  .import rng_127


on_reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs
  inx		; now X = 0
  stx PPUCTRL	; disable NMI
  stx PPUMASK 	; disable rendering
  stx $4010 	; disable DMC IRQs


  ;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit PPUSTATUS
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

  ;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit PPUSTATUS
  bpl vblankwait2

main:
  ;; Changing palette colors
  bit PPUSTATUS

  lda #$3f
  sta PPUADDR

  lda #$00
  sta PPUADDR

  lda #$01
  sta PPUDATA

  ;; Pallete Escape Hack
  lda #$3F
  sta PPUADDR
  lda #$0
  sta PPUADDR
  sta PPUADDR
  sta PPUADDR

  lda #%10000100                ; Enable NMI, PPUDATA writes increment downard
  sta PPUCTRL

  lda #%00001010                ; Enable background and leftmost column
  sta PPUMASK

  ;; First Update
  lda #$01                      ; Begin first update
  sta is_updating

generate_numbers:

  lda #123                      ; setting rng_seed
  sta rng_seed

  lda #231
  sta rng_seed+1


  ;; Initialize array with 0-127
  ldx #127
@loop:
  txa
  sta sorting_array, x
  dex
  bpl @loop

  jmp skip_shuffle
shuffle:
  ldy #127
  sty $00                       ; index = 127

@loop:                               ; do {
  jsr rng_127                   ; rng1 = rng_127()
  pha
  jsr rng_127                   ; rng2 = rng_127()
  tax
  pla
  tay

  lda sorting_array, x           ; tmp = sorting_array[rng1]
  pha

  lda sorting_array, y           ; sorting_array[rng1] = sorting_array[rng2]
  sta sorting_array, x

  pla                           ; sorting_array[rng2] = sorting_array[rng1]
  sta sorting_array, y

  ldy $00                       ; index--
  dey
  sty $00

  bpl @loop                        ; } while (index >= 0)
  skip_shuffle:

  ;; Update loop
update:
  @wait_update:
  lda is_updating
  beq @wait_update

  lda sorting_stage
  bne :+
  jsr init_stage_update
:

  ;; one day: implement code for other rendering stages

  lda #0
  sta is_updating

  jmp @wait_update

.proc init_stage_update
  lda init_stage_index
  cmp #SORTING_DATA_SIZE
  bmi :+                        ; if (init_stage_index >= SORTING_DATA_SIZE) {

  lda #$01
  sta sorting_stage             ; sorting_stage = 1;

  lda #NO_RENDER_COLUMN         ; render_columns_positions[1] = render_columns_positions[0] = NO_RENDER_COLUMN
  sta render_columns_positions
  sta render_columns_positions+1

  rts                           ; return;
:                               ; }

  ;; Calculating tiles for array[index] and array[index+1]
  ;; and filling it into render_columns[0:RENDER_COLUMN_HEIGHT]
  pha                           ; generate_tiles(
  tax                           ;   sorting_array[init_stage_index],
  lda sorting_array, X          ;   sorting_array[init_stage_index + 1],
  sta $00                       ;   0);

  lda sorting_array+1, X
  sta $01

  lda #0
  jsr generate_tiles

  ;; Calculating tiles for array[index+2] and array[index+3]
  ;; and filling it into render_columns[RENDER_COLUMN_HEIGHT:2*RENDER_COLUMN_HEIGHT]

  pla
  tax

  lda sorting_array+2, X
  sta $00

  lda sorting_array+3, X
  sta $01

  lda #RENDER_COLUMN_HEIGHT       ; generate_tiles(
  jsr generate_tiles            ;   sorting_array[init_stage_index+2],
                                ;   sorting_array[init_stage_index+3],
                                ;   RENDER_COLUMN_HEIGHT);

  lda init_stage_index
  lsr A
  sta render_columns_positions
  clc
  adc #1
  sta render_columns_positions+1

  lda init_stage_index          ; init_stage_index += 4
  clc
  adc #4
  sta init_stage_index

  rts
.endproc

  ;; TODO: review init stage update and weird memory thing in hex editor

  ;; Render routine
on_nmi:
  php
  pha

  lda is_updating               ; if (is_updating) {
  beq :+
  pla
  plp
  rti                           ; return
:                               ; }

  lda sorting_stage             ; if (sorting_stage == 0) {
  bne :+
  jsr init_stage_render      ; init_stage_render();
:                               ; }

  lda #1                        ; is_updating = 1
  sta is_updating

  pla
  plp

  rti                           ; return;

.proc init_stage_render

  lda render_columns_positions
  cmp #NO_RENDER_COLUMN
  bne :+
  rts
:
  lda render_columns_positions
  sta $00
  ldx #0

  jsr render_column

  lda render_columns_positions+1
  sta $00
  ldx #RENDER_COLUMN_HEIGHT

  jsr render_column

  bit PPUSTATUS

  lda #0
  sta PPUSCROLL

  lda #0
  sta PPUSCROLL

  rts
.endproc

  ;; $00: (column_index) index of the column to render
  ;; X: (array_offset) offset into render_columns to render. Usually 0 or COLUMN_HEIGHT.
  ;;
  ;; Clobbers: X, Y
.proc render_column

  bit PPUSTATUS

  lda $00
  cmp #COLUMNS_PER_SCREEN       ; if (column_index < COLUMNS_PER_SCREEN) {
  bpl :+
  lda #$20                      ; PPUADDR = 0x20 .. column_index;
  sta PPUADDR
  lda $00
  sta PPUADDR

  jmp :++                       ; } else {
:
  rts                           ; return
  lda #$24                      ; PPUADDR = 0x24 .. column_index;
  sta PPUADDR
  lda $00
  sta PPUADDR
:                               ; }

  ldy #RENDER_COLUMN_HEIGHT-1   ; counter = RENDER_COLUMN_HEIGHT - 1;

  txa
  clc
  adc #RENDER_COLUMN_HEIGHT-1     ; array_offset += RENDER_COLUMN_HEIGHT-1
  tax

@loop:                          ; do {
  lda render_columns,x          ; PPUDATA = render_columns[array_offset]
  sta PPUDATA
  dex                           ; array_offset--
  dey                           ; counter--
  bpl @loop                     ; } while (counter >= 0)

  ;; TODO: review rendering

  rts
.endproc

  ;; Generates the sequence of tiles for the two numbers ($00, $01).
  ;; Arguments:
  ;; $00: (x) The first number of the pair
  ;; $01: (y) The second number of the pair
  ;; A : (offset) The offset into render_columns to save result
  ;;
  ;; Clobbers:
  ;; $00, $01, $02, $03, X, Y
.proc generate_tiles

  tax                           ; i = offset

  ldy #RENDER_COLUMN_HEIGHT - 1   ; counter = 29

  @loop:                        ; do {

  ;; truncating first number
  lda $00                       ; truncated_x = x < 4 ? x : 4
  cmp #04
  bmi @skip_truncate
  lda #04
  @skip_truncate:
  sta $02

  ;; truncating second number
  lda $01                       ; truncated_y = y < 4 ? y : 4
  cmp #04
  bmi @skip_truncate2
  lda #04
  @skip_truncate2:
  sta $03

  ;; Tile Linearization
  lda $02                       ; tile_index = truncated_x * 5 + truncated_y
  asl A
  asl A
  adc $02
  adc $03

  sta render_columns, x           ; render_columns[i] = tile_index

  sec                           ; x -= truncated_x
  lda $00
  sbc $02
  sta $00

  sec
  lda $01                      ; y -= truncated_y
  sbc $03
  sta $01

  inx                           ; i++
  dey                           ; counter--

  bpl @loop                     ; } while (counter >= 0);
  rts
  .endproc



.segment "CHARS"

.incbin "pattern-table.bin"
