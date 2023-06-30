
.segment "CODE"

.include "vars_h.s"
.include "PPU.s"

.export compute_column_tiles
.export render_column
.export notify_update

  ;; Computes the column tiles for the sorting_array numbers at
  ;; the given indexes. This function completely fills render_columns
  ;; with the representing columns of the given indexes.
  ;;
  ;; Arguments:
  ;; local0: First index to notify column update
  ;; local1: Second index to notify column update
  ;;
  ;; Clobbers:
  ;; local0, local1, local2, local3, X, Y
.proc notify_update

  lda local0
  lsr A
  sta render_columns_positions

  lda local1
  lsr A
  sta render_columns_positions+1



  lda local1
  pha

  lda #0
  jsr compute_column_tiles_from_index

  pla
  sta local0
  lda #RENDER_COLUMN_HEIGHT
  jsr compute_column_tiles_from_index

  rts
.endproc

  ;; Computes the sequence of tiles for the column
  ;; that represents the value sorting_array at the
  ;; given index.
  ;;
  ;; Arguments:
  ;; local0: (index) The first number of the pair
  ;; A : (offset) The offset into render_columns to save result
  ;;
  ;; Clobbers:
  ;; local0, local1, local2, local3, X, Y
.proc compute_column_tiles_from_index
  pha
  lda local0
  and #$fe

  tax
  lda sorting_array, x
  sta local0

  lda sorting_array+1,x
  sta local1

  pla

  jmp compute_column_tiles
.endproc
  ;; Computes the sequence of tiles for the two numbers (local0, local1).
  ;; Arguments:
  ;; local0: (x) The first number of the pair
  ;; local1: (y) The second number of the pair
  ;; A : (offset) The offset into render_columns to save result
  ;;
  ;; Clobbers:
  ;; local0, local1, local2, local3, X, Y
.proc compute_column_tiles

  tax                           ; i = offset

  ldy #RENDER_COLUMN_HEIGHT - 1   ; counter = 29

  @loop:                        ; do {

  ;; truncating first number
  lda local0                       ; truncated_x = x < 4 ? x : 4
  cmp #04
  bmi @skip_truncate
  lda #04
  @skip_truncate:
  sta local2

  ;; truncating second number
  lda local1                       ; truncated_y = y < 4 ? y : 4
  cmp #04
  bmi @skip_truncate2
  lda #04
  @skip_truncate2:
  sta local3

  ;; Tile Linearization
  lda local2                       ; tile_index = truncated_x * 5 + truncated_y
  asl A
  asl A
  adc local2
  adc local3

  sta render_columns, x           ; render_columns[i] = tile_index

  sec                           ; x -= truncated_x
  lda local0
  sbc local2
  sta local0

  sec
  lda local1                      ; y -= truncated_y
  sbc local3
  sta local1

  inx                           ; i++
  dey                           ; counter--

  bpl @loop                     ; } while (counter >= 0);
  rts
  .endproc

  ;; Copies one column from the array render_columns into PPU
  ;;
  ;; local0: (column_index) index of the column to render
  ;; X: (array_offset) offset into render_columns to render. Usually 0 or COLUMN_HEIGHT.
  ;;
  ;; Clobbers: X, Y
.proc render_column

  bit PPUSTATUS

  lda local0
  cmp #COLUMNS_PER_SCREEN       ; if (column_index < COLUMNS_PER_SCREEN) {
  bpl :+
  lda #$20                      ; PPUADDR = 0x20 .. column_index;
  sta PPUADDR
  lda local0
  sta PPUADDR

  jmp :++                       ; } else {
:
  lda #$24                      ; PPUADDR = 0x24 .. (column_index - 32);
  sta PPUADDR                   ; // why - 32 you may ask, well for some reason unknown to me uh
  lda local0                    ; // the second nametable gets shifted a row downwards, so we subtract 32
  sec                           ; // to adjust for that
  sbc #32

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

  rts
.endproc
