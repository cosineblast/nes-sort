
  .include "vars_h.s"

  .code

    .export rng
    .export rng_127

  ;; Pseudo Random Number Generation using Galois LFSRs
  ;; Taken from NesDev wiki
  ;;
  ;; Clobbers: Y
.proc rng
  ldy #8     ; iteration count (generates 8 bits)
  lda rng_seed+0
:
  asl        ; shift the register
  rol rng_seed+1
  bcc :+
  eor #$39   ; apply XOR feedback whenever a 1 bit is shifted out
:
  dey
  bne :--
  sta rng_seed+0
  cmp #0     ; reload flags
  rts
.endproc

  ;; Like rng but limited to range 0-127 instead of 0-255
  ;; Clobbers: Y
.proc rng_127
  jsr rng
  cmp #128
  bmi :+
  sec
  sbc #128
:
  rts
.endproc
