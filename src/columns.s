
.segment "CODE"

.include "vars_h.s"
.include "io_registers_h.s"

.code


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
  pha
  lsr A
  sta local2
  sta render_columns_positions

  lda local1
  pha
  lsr A
  cmp local2

  bne :+
  lda #NO_RENDER_COLUMN
:
  sta render_columns_positions+1

  lda local1
  pha

  lda #0
  jsr compute_column_tiles_from_index

  pla
  sta local0
  lda #RENDER_COLUMN_HEIGHT
  jsr compute_column_tiles_from_index

  pla
  sta local1
  pla
  sta local0
  jsr compute_oam_data_for_update

  rts
.endproc

.proc compute_oam_data_for_update
  ;; Arguments:
  ;; local0: index0: First index to notify column update
  ;; local1: index1: Second index to notify column update
  ;;
  ;; Clobbers:
  ;; lots of stuff

  lda local0
  sta local4
  lda local1
  sta local5
  
  lda array_scroll_offset
  cmp local4
  bpl :+                        ; if (array_scroll_offset <= index0

  lda local4
  sec
  sbc array_scroll_offset       ; && index0 - array_scroll_offset < 64) {
  cmp #64
  bpl :+
  beq :+

  lda #00
  jsr compute_oam_single_column ; compute_oam_single_column(0)

  jmp :++
:                               ; }
  lda #00
  jsr zero_oam_buffer_half
:

  lda array_scroll_offset
  cmp local5
  bpl :+                        ; if (array_scroll_offset <= index1

  lda local5
  sec
  sbc array_scroll_offset       ; && index[1] - array_scroll_offset < 64) {
  cmp #64
  bpl :+
  beq :+

  lda #01
  jsr compute_oam_single_column ; compute_oam_single_column(1)

  jmp :++
:                               ; }
  lda #01
  jsr zero_oam_buffer_half
:

  rts
.endproc

.proc zero_oam_buffer_half
  ;; A: second_half: if nonzero, zero the 128 last bytes of the oam page
  ;; otherwiise, if 0 zero the 128 first bytes of oam page

  
  tax
  beq :+
  ldx #128
  jmp :++
  :
  ldx #00
  : ; index = second_half ? 128 : 0

  ldy #128           ; i = 128
@loop:               ; do {
  lda #00
  sta oam_buffer, x ; oam_buffer[index] = 0
  dey                ; i--
  inx                ; index++
  bne @loop          ; while (i != 0)
  rts
.endproc

.proc compute_oam_single_column
  ;; A: column_index: the column to render (0 or 1)
  ;; this parameter also dictates if values will be written in first or second
  ;; half of OAM buffer
  ;; local4,local5: array access indices

  tax
  tay

  lda #15
  sta local0                ; sprite_y = 15

;; this may cause issues.
  lda local4, x
  sec
  sbc array_scroll_offset
  lsr A
  asl A
  asl A
  asl A
  sta local1                ; sprite_x = render_columns_positions[column_index] * 8

  txa
  beq :+
  ldy #(2*RENDER_COLUMN_HEIGHT)
  jmp :++
  :
    ldy #RENDER_COLUMN_HEIGHT 
  : ; sprite_index = column_index == 0 ? RENDER_COLUMN_HEIGHT : 2 * RENDER_COLUMN_HEIGHT


  txa
  beq :+                   ; if (column_index != 0) {

  ldx #128                 ;   data_index = 128

  lda #RENDER_COLUMN_HEIGHT;
  sta local7               ;   stop_sprite_index = RENDER_COLUMN_HEIGHT

  jmp :++                  ; else {
  :

  ldx #00                  ;   data_index = 0

  lda #00
  sta local7               ;   stop_sprite_index = 0

  :                        ; }

  sta local7 ; stop = 

@loop:                      ;  do {
  dey                       ;   sprite_index -= 1
  
  lda local0
  sta oam_buffer, x         ;   oam_buffer[data_index] = sprite_y

  lda render_columns, y
  sta oam_buffer+1, x       ;   oam_buffer[data_index+1] = render_columns[sprite_index]

  lda #00
  sta oam_buffer+2, x       ;   oam_buffer[data_index+2] = 0

  lda local1
  sta oam_buffer+3, x       ;   oam_buffer[data_index+3] = sprite_x

  inx
  inx
  inx
  inx                       ;   data_index += 4

  lda local0
  clc
  adc #8
  sta local0                ;   sprite_y += 8

  tya
  cmp local7
  bne @loop
  @loop_end:                ; } while (sprite_index != stop_sprite_index)

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


.export compute_column_tiles
.export render_column
.export render_columns_from_positions
.export notify_update
