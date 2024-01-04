.include "vars_h.s"

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

.proc sort_stage_update

  jsr get_input

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

;; TODO: document sorting routine ABI
.proc sort_array

;; Change 'insertion_sort' here to use other sorting algorithms
;; (e.g heap_sort)
  jsr insertion_sort

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



.export coroutine_start_location = sort_array
.export swap
.export sort_stage_update

