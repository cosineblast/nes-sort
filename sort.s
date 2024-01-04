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

.proc sort_array
  jsr insertion_sort

  lda #1
  sta local2
  jsr coroutine_yield     ;  yield 1
  @UB:                    ; resuming again is undefined behaviour
  jmp @UB
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

    lda local0              ;       swap_array(index, index-1);
    sta sorting_array, x
    lda local1
    sta sorting_array-1, x

    stx local0              ;       result[0] = index;
    dex
    stx local1              ;       result[1] = index-1;

    stx @backward_index     ;       backward_index = index - 1;

    lda #0
    sta local2
    jsr coroutine_yield     ;       yield 0

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
  asl @index
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
  jsr coroutine_yield
.endproc



.export coroutine_start_location = sort_array
.export sort_stage_update

