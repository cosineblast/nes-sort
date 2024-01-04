
.include "vars_h.s"

;; sort.s
.import swap

.code

.proc insertion_sort

@forward_index = local6
@backward_index = local7

    lda #1
    sta @forward_index      ; forward_index = 1;
    sta @backward_index     ; backward_index = 1;

    @full_loop:             ; while (true) {

    @insert_loop:           ;   while (index != 0 && sorting_array[index] < sorting_array[index-1]) {
                            ;
    ldx @backward_index     ;
                            ;
    beq :+                  ;
                            ;
    lda sorting_array-1, x  ;
    sta local0              ;
                            ;
    lda sorting_array, x    ;
    sta local1              ;
                            ;
    cmp local0              ;
    bpl :+                  ;

    ; swap(index, index - 1)
    txa
    dex
    jsr swap
    dec @backward_index

    jmp @insert_loop        ;     }
:

                            ; // it's ok, move to next forward index

    ldx @forward_index      ;
    inx                     ;   backward_index  = ++forward_index;
    stx @forward_index      ;
    stx @backward_index     ;


    lda @forward_index      ; if (forward_index >= SORTING_DATA_SIZE) {
    cmp #SORTING_DATA_SIZE
    bmi :+

    rts                     ; return;
:                           ; }

    jmp @full_loop          ;}

.endproc

.export insertion_sort
