

.include "vars_h.s"

;; column.s
.import notify_update

;; coroutine.s
.import coroutine_resume
.import coroutine_yield


.code

;; .exports are at the bottom of the file 
;;   for scope reasons.

.proc sort_stage_update

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


  ;; The is the index of the element that is being inserted
  ;; by the current insertion of the sort
  ; local6 = forward_index

  ;; This is the index of the element that we are comparing against
  ;; in the current insertion of the insertion sort
  ; local7 = backward_index (also known as just "index")

  ;; Insertion routine:
  ;; the backward index refers to the index of the element being inserted right now, the
  ;; forward refers to the original index of that element before its insertion.
  ;; 
  ;; This routine is intended to be called as a coroutine, and it does not return, 
  ;; it yields through coroutine_yield
  ;;
  ;; Arguments: None
  ;;
  ;; yields:
  ;; local2: 1 if this was a final yield, 0 otherwise
  ;; local0, local1: The indexes of the two values that were swapped 
  ;;   (if nonfinal yield)
  ;; Clobbers: specified by coroutine_yield

.proc insertion_sort

    lda #1 
    sta local6                      ; forward_index = 1;
    sta local7                      ; backward_index = 1;

    @full_loop:                     ; while (true) {

    @insert_loop:                   ;   while (index != 0 && sorting_array[index] < sorting_array[index-1]) {
                                    ;
    ldx local7                      ;
                                    ;
    beq :+                          ;
                                    ;
    lda sorting_array-1, x          ;
    sta local0                      ;
                                    ;
    lda sorting_array, x            ;
    sta local1                      ;
                                    ;
    cmp local0                      ;
    bpl :+                          ;

    lda local0                      ;       swap_array(index, index-1);
    sta sorting_array, x
    lda local1
    sta sorting_array-1, x

    stx local0                      ;       result[0] = index;
    dex
    stx local1                      ;       result[1] = index-1;

    stx local7                      ;       backward_index = index - 1;

    lda #0
    sta local2
    jsr coroutine_yield             ;       yield 0

    jmp @insert_loop                ;     }
:                                   

                                    ; // it's ok, move to next forward index

    ldx local6  ;
    inx                               ;   backward_index  = ++forward_index;
    stx local6  ;
    stx local7 ;


    lda local6     ; if (forward_index >= SORTING_DATA_SIZE) {
    cmp #SORTING_DATA_SIZE
    bmi :+

    lda #1
    sta local2
    jsr coroutine_yield                  ;  yield 1
    @UB: ; resuming again is undefined behaviour
    jmp @UB
:                                        ; }

    jmp @full_loop                     ;}

.endproc

.export coroutine_start_location = insertion_sort
.export sort_stage_update

