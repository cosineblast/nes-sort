
;; coroutine.s 
;; Implementation for the sorting coroutine.

;; TODO: make header file for this

.code

.export coroutine_yield
.export coroutine_resume

.import coroutine_start_location

.include "vars_h.s"

;; Swaps the 6502 stack ($0100..$01FF) with the 
;; coroutine_stack.
;; Clobbers: A, X, Y
.macro swap_stacks
;; TODO: don't copy entire stack, copy only the stack used 
;; by the stack registers.

ldx #$00                      ; i = 0
@stack_copy_loop:             ; do {
  lda stack_start, x          ;
  ldy coroutine_stack_start, x;   @swap(&stack[i], &coroutine_stack[i])
  sta coroutine_stack_start, x;
  tya                         ;   // sty can't do absolute, x access
  sta stack_start, x          
  inx                         ;   i++;
  bne @stack_copy_loop        ; } while (i != 0)
.endmacro

.macro swap_s_registers
  tsx 
  ldy coroutine_s_register
  stx coroutine_s_register
  tya
  tax
  txs
.endmacro

  ;; coroutine_yield: 
  ;; This special procedure attempts to implement 
  ;; coroutine 'yield' behaviour. 
  ;; This procedure assumes coroutine_resume
  ;; was called at least once.
  ;;
  ;; When this procedure is called, the current stack¹
  ;; is saved, alongside all 8 the localX registers. 
  ;;
  ;; Then, the stack is reset to its state before the last 
  ;; coroutine_resume call and the control is given back to 
  ;; the coroutine_resume return location.
  ;;
  ;; Then, if another coroutine_resume call is performed,
  ;; the coroutine state is restored, and this
  ;; procedure returns.
  ;;
  ;; it is expected that one calls this with jsr.
  ;; 
  ;; calling coroutine_yield clobbers:
  ;;  literally everything other than 
  ;;  the values mentioned to be saved.
  ;;  status flags need not be saved.
  ;;
  ;; calling coroutine_resume clobbers:
  ;;  everything but the stack¹ and S
  ;;  
  ;; ¹the implementation may copy only the stack up to 
  ;;  the S register, instead of the entire stack.
.proc coroutine_yield
  ;; save local registers
  ;; note: yield doesn't have to restore 
  ;;  the local registers of the current resume call
  ;;  so we don't have to swap the locals with coroutine_locals
  ldx #LOCAL_REGISTER_COUNT-1         ;   i = LOCAL_REGISTER_COUNT - 1;
@local_copy_loop:                     ;   while (i >= 0) {
  lda local0, x                     ;     
  sta coroutine_local0, x           ;    *(coroutine_local0 + i) = *(local0 + 1);
  dex                                 ;     i -= 1;
  bpl @local_copy_loop                ;   }

  ;; swap 6502 stack with coroutine_stack
  swap_stacks

  ;; swap the stack pointer register 
  swap_s_registers

  rts
.endproc

  ;; see coroutine_yield

  ;; This routine resumes execution of the current sorting coroutine.
.proc coroutine_resume
  swap_s_registers

  swap_stacks

 ;; restore local registers

  ldx #LOCAL_REGISTER_COUNT-1;   i = LOCAL_REGISTER_COUNT - 1;
@local_copy_loop:            ;   while (i >= 0) {
  lda coroutine_local0, x    ;
  sta local0, x              ;     *(local0 + i) = *(coroutine_local0 + 1);
  dex                        ;     i -= 1;
  bpl @local_copy_loop       ;   }

  ;; as we have restored all relevant information (S, locals, stack)
  ;; the stack pointer points to the return address of the jsr call to yield 
  ;; so we can rts to where yield left off. however, if this is the first 
  ;; time we're running, then there's nowhere we 'left off', so we jump to our
  ;; start location instead

  lda coroutine_started ; 
  beq :+
  rts
  :
  lda #1
  sta coroutine_started
  jmp coroutine_start_location
.endproc
