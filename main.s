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

  ;; Array of 60 bytes containing the tiles for the two
  ;; columns that will be rendered on the next frame.
  ;; first 30 elements represent the first column,
  ;; last 30  elements represet the second column.
  ;; $ff - 60
  diff_columns = $c3

.segment "ABS_VARS": absolute

  ;; bool, whether the program is currently runnning update code or not.
  ;; 0 if an update is not running (and it is ok for a render to run).
  ;; 1 if update code is/should be running,
  is_updating = $0200

  ;; 0 when the program is doing the initial render of the tiles
  ;; 1 when the program is already rendering the algorithm steps
  ;; 2 when the program is done with the algorithm
  sorting_stage = $0201

  ;; The seed for the random number generation
  ;; Two bytes
  seed = $0202

  ;; Two bytes
  render_columns_id = $0204



  ;; The numbers to be sorted
  ;; 128 bytes
  sort_numbers = $0300


.segment "CODE"


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

  ;; First Update
  lda #$01                      ; Begin first update
  sta is_updating

generate_numbers:

  lda #123                      ; setting seed
  sta seed

  lda #231
  sta seed+1

  ;; Initialize array with 0-127
  ldx #127
@loop:
  txa
  sta sort_numbers, x
  dex
  bpl @loop

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

  lda sort_numbers, x           ; tmp = sort_numbers[rng1]
  pha

  lda sort_numbers, y           ; sort_numbers[rng1] = sort_numbers[rng2]
  sta sort_numbers, x

  pla                           ; sort_numbers[rng2] = sort_numbers[rng1]
  sta sort_numbers, y

  ldy $00                       ; index--
  dey
  sty $00

  bpl @loop                        ; } while (index >= 0)

  ;; Update loop
update:
  @wait_update:
  lda is_updating
  beq @wait_update

  lda sorting_stage
  bne :+
  jsr initial_stage_update
:

  ;; one day: implement code for other rendering stages

  lda #0
  sta is_updating

  jmp @wait_update

.proc initial_stage_update
  rts
.endproc


  ;; Like rng but limited to range 0-127 instead of 0-255
  ;; Clobbers: Y
.proc rng_127
  jsr rng
  cmp #128
  bmi :+
  sec
  sbc #128
:
  rts
.endproc

  ;; Render routine
on_nmi:
  sta is_updating               ; if (is_updating) {
  beq :+
  rti                           ; return
:                               ; }

  lda sorting_stage             ; if (sorting_stage == 0) {
  bne :+
  jsr initial_stage_render      ; initial_stage_render();
:                               ; }

  lda #1                        ; is_updating = 1
  sta is_updating

  rti                           ; return;

.proc initial_stage_render
  rts
.endproc

  ;; Pseudo Random Number Generation using Galois LFSRs
  ;; Taken from NesDev wiki
  ;;
  ;; Clobbers: Y
.proc rng
  ldy #8     ; iteration count (generates 8 bits)
  lda seed+0
:
  asl        ; shift the register
  rol seed+1
  bcc :+
  eor #$39   ; apply XOR feedback whenever a 1 bit is shifted out
:
  dey
  bne :--
  sta seed+0
  cmp #0     ; reload flags
  rts
.endproc

  ;; Generates the sequence of tiles for the two numbers ($00, $01).
  ;; Arguments:
  ;; $00: The first number of the pair
  ;; $01: The second number of the pair
  ;; A: The offset into diff_columns to save result
  ;;
  ;; Clobbers:
  ;; $00, $01, $02, $03, A, X
  .proc generate_tiles

  clc                           ; i = argX + 29
  adc 29
  tax

  @loop:                        ; do {

  ;; truncating first number
  lda $00                       ; truncated_x = x < 4 ? x : 4
  cmp #$04
  bmi @skip_truncate
  lda #$04
  @skip_truncate:
  sta $02

  ;; truncating second number
  lda $01                       ; truncated_y = y < 4 ? y : 4
  cmp #$04
  bmi @skip_truncate2
  lda #$04
  @skip_truncate2:
  sta $03

  ;; Tile Linearization
  lda $02                       ; tile_index = truncated_x * 5 + truncated_y
  asl A
  asl A
  adc $02
  adc $03

  sta diff_columns, x           ; diff_columns[i] = tile_index

  sec                           ; x -= truncated_x
  lda $00
  sbc $02
  sta $00

  lda $01                      ; y -= truncated_y
  sbc $03
  sta $01

  dex                           ; i--
  bpl @loop                     ; } while (i >= 0);
  rts
  .endproc



.segment "CHARS"

.incbin "pattern-table.bin"
