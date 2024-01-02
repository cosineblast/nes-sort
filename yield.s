
.code

.export yield
.import yield_return_location

.include "vars_h.s"

;; Swaps the 6502 stack ($0100..$01FF) with the 
;; coroutine_stack.
;; Clobbers: A, X, Y
.macro swap_stacks
;; TODO: don't copy entire stack, copy only the stack used 
;; by the stack registers.
ldx #$00                           ; i = 0
@stack_copy_loop:                  ; do {
  lda (stack_start, x)               ;   
  ldy (coroutine_stack_start, x)     ;   @swap(&stack[i], &coroutine_stack[i])
  sta (coroutine_stack_start, x)     ;  
  sty (stack_start, x)               ;   
  inx                                ;   i++;
  bne @stack_copy_loop               ; } while (i != 0)
  .endmacro

  .macro swap_s_registers
  tsx 
  ldy coroutine_s_register
  stx coroutine_s_register
  tyx
  txs
  .endmacro

  ;; coroutine_yield: 
  ;; This special procedure attempts to implement 
  ;; coroutine 'yield' behaviour. 
  ;; This procedure assumes coroutine_resume or
  ;; coroutine_init was called at least once.
  ;;
  ;; When this procedure is called, the current stack¹
  ;; is saved, alongside the A, X, Y, S registers and  
  ;; all 8 the localX registers. 
  ;;
  ;; Then, the control is given back to yield_return_location 
  ;; and the stack is reset to its state before the last 
  ;; coroutine_resume call.
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
  ;; save A,X,Y registers
  sta coroutine_a_register
  stx coroutine_x_register
  sty coroutine_y_register

  ;; save local registers
  ;; note: yield doesn't have to restore 
  ;;  the local registers of the current resume call
  ;;  so we don't have to swap
  ldx #LOCAL_REGISTER_COUNT-1         ;   i = LOCAL_REGISTER_COUNT - 1;
@local_copy_loop:                     ;   while (i >= 0) {
  lda (local0, x)                     ;     
  sta (coroutine_local0, x)           ;    *(coroutine_local0 + i) = *(local0 + 1);
  dex                                 ;     i -= 1;
  bpl @local_copy_loop                ;   }

  ;; swap 6502 stack with coroutine_stack
  swap_stacks

  ;; swap the stack pointer register 
  swap_s_registers

  ;; give control back to yield_return_location
  jmp yield_return_location
.endproc

  ;; see coroutine_yield

  ;; This routine resumes execution of the current sorting coroutine.
  ;; it assumes that the coroutine has already yielded at least once
.proc coroutine_resume
  swap_s_registers

  swap_stacks

  ;; restore local registers
  ldx #LOCAL_REGISTER_COUNT-1         ;   i = LOCAL_REGISTER_COUNT - 1;
@local_copy_loop:                     ;   while (i >= 0) {
  lda (coroutine_local0, x)           ;     
  sta (local0, x)                     ;     *(local0 + i) = *(coroutine_local0 + 1);
  dex                                 ;     i -= 1;
  bpl @local_copy_loop                ;   }

  ;; restore A, X and Y registers
  ldy coroutine_y_register
  ldx coroutine_x_register
  lda coroutine_a_register

  ;; as we have restored all relevant information (A,B,X,S, locals, stack)
  ;; the stack pointer points to the return address of the jsr call to yield 
  ;; so we can rts to where yield left off
  rts

.endproc

;; Initializes the coroutine state.
;; after calling this function, the execution code is considered to be 
;; "in the coroutine", and one may call yield for the first time.
;; clobbers: A
.proc coroutine_init
  lda #01
  sta coroutine_started
  rts
.endproc

