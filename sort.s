
.code

.include "vars_h.s"

.export sort_stage_update

.import notify_update

    ;; TODO: review this

.proc sort_stage_update

    lda insertion_sort_has_started ; if (insertion_sort_has_started) {
    bne @not_first_update          ;
    jsr first_update               ;    (result, swap_indexes) = first_update();
    jmp @end
@not_first_update:                 ; else {
    jsr enter_insert               ;    (result, swap_indexes) = enter_insert();
@end:                              ; }

    bne @no_yield                  ; if (result == 0) {

    jmp notify_update           ;      notify_update(swap_indexes);
                                ;      return;


@no_yield:                         ; }

    ;; TODO: change sorting stage to done.
    rts
.endproc


.proc first_update
    lda #1
    sta insertion_sort_backward_index

    lda #1
    sta insertion_sort_forward_index

    jmp enter_insert
.endproc



    ;; (re) Enters element insertion routine:
    ;; the backward index refers to the index of the element being inserted right now, the
    ;; forward refers to the original index of that element before its insertion.
    ;;
    ;; When this function returns, it is either because of a yield (meaning a swap has occurred),
    ;; or because of a final return. After a yield is
    ;;
    ;; Calling this function effectively resumes it from its previous state in the insertion.
    ;;
    ;; Arguments: None
    ;;
    ;; Returns:
    ;; A: 0 if this was a yield return, 1 if this was a final return
    ;; local0, local1: The indexes of the two values
    ;;
    ;;
    ;; Clobbers: X, local0, local1

.proc enter_insert                    ; while (true) {
    ldx insertion_sort_backward_index ;     index = backward_index;

    beq :+

    lda sorting_array-1, x
    sta local0

    lda sorting_array, x
    sta local1

    cmp local0                              ; if (index != 0 && sorting_array[index] < sorting_array[index-1]) {
    bpl :+

    lda local0                              ;   swap_array(index, index-1);
    sta sorting_array, x
    lda local1
    sta sorting_array-1, x

    stx local0                      ;   result[0] = index;
    dex
    stx local1                    ;   result[1] = index-1;

    stx insertion_sort_backward_index       ;   backward_index = index - 1;

    lda #0
    rts                                     ;   yield; // (return 0)
:                                           ; } else {

    ;; // it's ok, move to next forward index

    ldx insertion_sort_forward_index        ;
    inx                                     ; backward_index  = ++forward_index;
    stx insertion_sort_forward_index
    stx insertion_sort_backward_index


    lda insertion_sort_forward_index        ; if (forward_index >= SORTING_DATA_SIZE) {
    cmp #SORTING_DATA_SIZE
    bmi :+

    lda #1
    rts                                     ;  return; // (return 1)
:                                           ; }

    jmp enter_insert                  ;}



.endproc
