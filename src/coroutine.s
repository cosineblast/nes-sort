
;; coroutine.s
;; Implementation for the sorting coroutine.

;; This program implements a coroutine mechanism for the sorting algorithms.
;; When the sorting algorithm is to be started, one calls the
;; coroutine_resume subroutine for the first time.

;; When coroutine_resume is executed, it copies the execution context
;; (stack, S register)
;; to a spare memory location.
;; After that is done, if coroutine_resume is being
;; executed for the first time, it will
;; reset the execution context to a default one, and
;; jump to coroutine_start_location, thus starting the coroutine execution.

;; The coroutine code should eventually call the coroutine_yield function.
;; Whenever that happens, the execution context (stack, locals, S register)
;; is copied to a spare location, and the execution context saved
;; earlier by coroutine_resume is restored. coroutine_yield
;; will then jump to the return location of the earlier coroutine_resume call.

;; After the 'return' of coroutine_resume (performed by coroutine_yield),
;; the code may decide to call coroutine_resume once again. Once that happens,
;; the execution will be saved.

;; However, this time, instead of resetting the execution context and jumping
;; to coroutine_start_location, coroutine_resume will restore the execution
;; context saved in the latest coroutine_yield call, and will jump to its return location.

;; It is worth noting that coroutine_yield saves the local registers, but coroutine_resume doesn't.
;; This is intentional, and one of the side effects of this, is that
;; after coroutine_resume returns, it is possible to inspect
;; the local variables of the coroutine at yield point.

.export coroutine_yield
.export coroutine_resume

.import coroutine_start_location

.include "vars_h.s"

.code

;; helper macros

;; Swaps the 6502 stack ($0100..$01FF) with the
;; coroutine_stack. It does not copy the entire
;; stack, but only the portions apparently used
;; (by either the S register or coroutine_s_register)
;; Clobbers: A, X, Y
.macro swap_stacks

; i = S;
; if (S >= coroutine_s_register) {
tsx
txa
cmp coroutine_s_register
bcc :+

; i = coroutine_s_register;
ldx coroutine_s_register

; }
:

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

.proc coroutine_resume
  swap_stacks

  swap_s_registers

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

  ldx #$ff
  txs ; we're good to go!

  jmp coroutine_start_location
.endproc
