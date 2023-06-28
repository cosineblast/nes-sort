
.code

.include "vars_h.s"

.export sort_stage_update

.proc sort_stage_update

    lda insertion_sort_forward_index ; if (forward_index >= SORTING_DATA_SIZE) {
    cmp #SORTING_DATA_SIZE
    bmi :+
    lda #2
    sta current_sorting_stage
    rts                         ; return;
:                               ; }


    rts
.endproc
