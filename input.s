
.include "vars_h.s"
.include "IO_REGISTERS.s"

.code

.proc get_input

  lda #1
  sta local0

;; Tell the controller to start reading user input
;; into its register
  sta JOY1

;; Tell the controller to hold on the
;; current value in its register
  lda #0
  sta JOY1

@read_loop:
  lda JOY1
  lsr A
  rol local0
  bcc @read_loop

  lda local0
  sta controller_value

  rts

.endproc

.export get_input
