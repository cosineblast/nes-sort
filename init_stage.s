
.include "vars_h.s"
.include "IO_REGISTERS.s"

.import render_columns_from_positions
.import compute_column_tiles

.code


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

.proc init_stage_render

  jsr render_columns_from_positions

  bit PPUSTATUS

  lda #0
  sta PPUSCROLL

  lda #224
  sta PPUSCROLL

  rts
.endproc


.export init_stage_update
.export init_stage_render
