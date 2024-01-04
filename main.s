.include "IO_REGISTERS.s"

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

  .include "vars_h.s"

.segment "CODE"


  .import rng
  .import rng_127
  .import compute_column_tiles
  .import render_column
  .import sort_stage_update

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
  lda #0
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

  lda #0
  sta PPUADDR

  lda #$0f
  sta PPUDATA

  lda #$20
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
  lda #1                      ; Begin first update
  sta is_updating

generate_numbers:

  lda #231                      ; setting rng_seed
  sta rng_seed

  lda #$ff
  sta rng_seed+1


  ;; Initialize array
  ;; 0..100 is initalized with 0..100
  ;; 101..127 is initalized with 1..7

  ; for (i8 i = 100; i >= 0;  i--) {
  ldx #100
@loop:

  ; sorting_array[i] = i
  txa
  sta sorting_array, x

  ; }
  dex
  bpl @loop

  ; j = 0
  ; for (i = 101; i != 127; i++) {
  ldx #101
  ldy #0
@loop2:

  ; sorting_array[i] = j
  tya
  sta sorting_array, x

  ; j += 4
  iny
  iny
  iny
  iny

  ; i += 1
  inx
  txa

  cmp #127
  bne @loop2
  ; }



  ;; jmp skip_shuffle
shuffle:

  ; index = 127
  ldy #127
  sty local0

  ; do {
@loop:

  ; rng1 = rng_127()
  jsr rng_127
  pha

  ; rng2 = rng_127()
  jsr rng_127
  tax
  pla
  tay

  ; tmp = sorting_array[rng1]
  lda sorting_array, x
  pha

  ; sorting_array[rng1] = sorting_array[rng2]
  lda sorting_array, y
  sta sorting_array, x

  ; sorting_array[rng2] = sorting_array[rng1]
  pla
  sta sorting_array, y

  ; index--
  ldy local0
  dey
  sty local0

  ; } while (index >= 0)
  bpl @loop
  skip_shuffle:

  ;; Update loop

update:

  ; while (true) {

  ; while (!is_updating) {  }
  @wait_update:
  lda is_updating
  beq @wait_update

  ; if (current_sorting_stage == 0) {
  ;   init_stage_update()
  ; }
  ; else {
  ;   sort_stage_update()
  ; }
  lda current_sorting_stage
  beq @is_init
  cmp #PROGRAM_STAGE_SORT
  beq @is_sort
  jmp @end

  @is_init:
  jsr init_stage_update
  jmp @end
  @is_sort:
  jsr sort_stage_update
  @end:

  ; is_updating = 0
  lda #0
  sta is_updating

  ; }
  jmp @wait_update

;; init_stage_update()
;; TODO: document this
.proc init_stage_update

  ; if (init_stage_index >= SORTING_DATA_SIZE) {
  lda init_stage_index
  cmp #SORTING_DATA_SIZE
  bmi :+

  ; current_sorting_stage = 1;
  lda #1
  sta current_sorting_stage

  ; render_columns_positions[0] = NO_RENDER_COLUMN;
  ; render_columns_positions[1] = NO_RENDER_COLUMN;
  lda #NO_RENDER_COLUMN
  sta render_columns_positions
  sta render_columns_positions+1

  ; return;
  rts

  ; }
:
  ;; Calculating tiles for array[index] and array[index+1]
  ;; and filling it into render_columns[0:RENDER_COLUMN_HEIGHT]

; compute_column_tiles(
;   sorting_array[init_stage_index],
;   sorting_array[init_stage_index + 1],
;   0);

  pha
  tax
  lda sorting_array, X
  sta local0

  lda sorting_array+1, X
  sta local1

  lda #0
  jsr compute_column_tiles

  ;; Calculating tiles for array[index+2] and array[index+3]
  ;; and filling it into render_columns[RENDER_COLUMN_HEIGHT:2*RENDER_COLUMN_HEIGHT]

  pla
  tax

 ; compute_column_tiles(
 ;   sorting_array[init_stage_index+2],
 ;   sorting_array[init_stage_index+3],
 ;   RENDER_COLUMN_HEIGHT);

  lda sorting_array+2, X
  sta local0
  lda sorting_array+3, X
  sta local1
  lda #RENDER_COLUMN_HEIGHT
  jsr compute_column_tiles


  ; render_columns_position[0] = init_stage_index/2
  lda init_stage_index
  lsr A
  sta render_columns_positions

  ; render_columns_positions[1] = init_stage_index/2 + 1
  clc
  adc #1
  sta render_columns_positions+1

  ; init_stage_index += 4
  lda init_stage_index
  clc
  adc #4
  sta init_stage_index

  ; return
  rts
.endproc

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

  lda current_sorting_stage
  beq @is_init
  cmp #1
  beq @is_sort
  jmp @end

@is_init:                    ; if (current_sorting_stage == 0) {
  jsr init_stage_render      ;      init_stage_render();
  jmp @end                   ; }

@is_sort:                       ; else if (sortin_stage == 1) {
  jsr sort_stage_render         ;   current_sorting_stage_render();
@end:                           ; }

  lda #1                        ; is_updating = 1
  sta is_updating

  pla
  plp

  rti                           ; return;

.proc init_stage_render

  jsr render_columns_from_positions

  bit PPUSTATUS

  lda #0
  sta PPUSCROLL

  lda #224
  sta PPUSCROLL

  rts
.endproc

.proc render_columns_from_positions
  lda render_columns_positions  ; if (render_column_positions[0] != NO_RENDER_COLUMN) {
  cmp #NO_RENDER_COLUMN
  beq :+

  sta local0                    ; render_column(render_column_positions[0], 0);
  ldx #0
  jsr render_column             ; }
:
  lda render_columns_positions+1 ; if (render_columns_positions[1] != NO_RENDER_COLUMN) {
  cmp #NO_RENDER_COLUMN
  beq :+

  sta local0                    ; render_column(render_columns_positions[1], RENDER_COLUMN_HEIGHT);
  ldx #RENDER_COLUMN_HEIGHT
  jsr render_column
:
  rts
.endproc

.proc sort_stage_render

  jsr render_columns_from_positions

  bit PPUSTATUS

  lda #0
  sta PPUSCROLL

  lda #224
  sta PPUSCROLL

.endproc



.segment "CHARS"

.incbin "pattern-table.bin"
