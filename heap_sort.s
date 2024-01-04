
.include "vars_h.s"

;; sort.s
.import swap

.code

.proc heap_sort
  lda #SORTING_DATA_SIZE
  lsr

@loop:
  ldx #SORTING_DATA_SIZE
  pha
  jsr sift_down
  pla

  sec
  sbc #1
  bpl @loop

  rts
.endproc

;; arguments:
;; A: index
;; X: size
.proc sift_down
@index = local0
@size = local1
@left_index = local2
@right_index = local3
@left_value = local4

  sta @index
  stx @size

@loop:

  ; if (index >= size / 2) { break; }
  lda @size
  lsr
  cmp @index
  beq @end_loop
  bcc @end_loop

 ; left_index = (index << 1) + 1;
 ; right_index = (index << 1) + 2;
  lda @index
  asl
  tax
  inx
  stx @left_index
  inx
  stx @right_index

 ; left_value = sorting_array[left_index]
  ldx @left_index
  lda sorting_array, x
  sta @left_value

  ; if (right_index == size) {
  lda @right_index
  cmp @size
  bne @two_children

  ; if (left_value > value) {
  ldx @index
  lda sorting_array, x
  cmp @left_value
  bcs @end_loop

  ; swap(index, left_index)
  lda @index
  ldx @left_index
  jsr swap

  ; } break;
  jmp @end_loop

 ; } else
@two_children:

; u8 max_index =
;   right_value >= left_value
;     ? right_index : left_index;
  ldy @left_index

  ldx @right_index
  lda sorting_array, x
  cmp @left_value
  bcc :+
  ldy @right_index
  :

;; // reassign registers
@max_value = @left_index

  ; max_value = sorting_array[max_index]
  lda sorting_array, y
  sta @max_value

  ; if (value < max_value) {
  ldx @index
  lda sorting_array, x
  cmp @max_value
  bcs @end_loop

  ; swap(max_index, index)

  ; // @push(size); @push(max_index)
  lda @size
  pha
  tya
  pha

  tya
  ldx @index
  jsr swap

  ; // @pop(max_index); @pop(size)
  pla
  sta @index
  pla
  sta @size

  jmp @loop

@end_loop:
rts

.endproc

.export heap_sort
