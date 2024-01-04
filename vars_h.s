
  ;; vars_h.s

  ;; this header file contains the imports for all
  ;; the global variables in the program.

  ;; their definitions lie in var.s

.include "constants_h.s"

.zeropage

.import local0
.import local1
.import local2
.import local3
.import local4
.import local5
.import local6
.import local7
.import render_columns

.bss

.import is_updating
.import current_sorting_stage
.import rng_seed
.import render_columns_positions
.import init_stage_index

.import sorting_array
.import aux_array

.import coroutine_started
.import coroutine_s_register
.import coroutine_local0

.import coroutine_stack_start

