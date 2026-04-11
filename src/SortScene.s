.include "vars_h.s"
.include "IO_REGISTERS.s"

;; column.s
.import notify_update

;; coroutine.s
.import coroutine_resume
.import coroutine_yield

;; insertion_sort.s
.import insertion_sort

;; heap_sort.s
.import heap_sort

;; input.s
.import get_input




.code

;; .exports are at the bottom of the file
;;   for scope reasons.

.proc SortScene_update

  jsr handle_input




    jsr coroutine_resume  ;    (result, swap_indexes) = coroutine_resume();

    lda local2 ; note: local2 is the register that indicates
               ; whether the sorting coroutine has ended or not

    bne @coroutine_done              ; if (result == 0) {

    jmp notify_update                ;      notify_update(swap_indexes);
                                     ;      return;
@coroutine_done:                           ; }

    lda #PROGRAM_STAGE_DONE          ; else {
    sta current_sorting_stage        ;   current_sorting_stage = PROGRAM_STAGE_DONE;
    rts                              ; return;
                                     ; }
.endproc

.proc handle_input
  jsr get_input

  ; if ((controller_value & JOY_RIGHT) &&
  ;      array_scroll_offset < SORTING_DATA_SIZE) {
  lda controller_value
  and #JOY_RIGHT
  beq :+
  lda array_scroll_offset
  cmp #SORTING_DATA_SIZE/2
  bcs :+

  ; array_scroll_offset += 1
  inc array_scroll_offset

  ; }
  :

  ; if ((controller_value & JOY_LEFT) &&
  ;      array_scroll_offset != 0) {
  lda controller_value
  and #JOY_LEFT
  beq :+
  lda array_scroll_offset
  beq :+
  dec array_scroll_offset

: ; }

  rts
.endproc

;; TODO: document sorting routine ABI
.proc sort_array

;; Change 'insertion_sort' here to use other sorting algorithms
;; (e.g heap_sort)
  jsr heap_sort

  lda #1
  sta local2
  jsr coroutine_yield     ;  yield 1
  @UB:                    ; resuming again is undefined behaviour
  jmp @UB
.endproc

;; A: index0
;; X: index1
;; clobbers: A,X,Y, local0, local1, local2
.proc swap

; tmp = array[index0]
  tay
  lda sorting_array, x
  sta local0

; array[index0] = array[index1]
  lda sorting_array, y
  sta sorting_array, x

; array[index1] = tmp
  lda local0
  sta sorting_array, y


  stx local0
  sty local1
  lda #0
  sta local2
  jmp coroutine_yield
.endproc

.proc SortScene_render

.import render_columns_from_positions
  jsr render_columns_from_positions

  bit PPUSTATUS

  ;; we reset PPUCTRL, because after touching
  ;; ppuaddr, the base namespace gets modified.
  lda ppuctrl_value
  sta PPUCTRL
  sta ppuctrl_value

  ; set_PPUSCROLL(array_scroll_offset * 4);
  bit PPUSTATUS
  lda array_scroll_offset
  asl A
  asl A
  sta PPUSCROLL

  ; set_PPUSCROLL(224);
  lda #224
  sta PPUSCROLL

  rts

.endproc


.export coroutine_start_location = sort_array
.export swap
.export SortScene_update
.export SortScene_render

