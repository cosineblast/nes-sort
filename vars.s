
;; vars.s

;; this target file contains the definition for all the variables
;; in the code, and its imports are located in vars_h.s


.zeropage

.include "constants_h.s"

;; General Purpose zero page "registers"
local0: .res 1
local1: .res 1
local2: .res 1
local3: .res 1
local4: .res 1
local5: .res 1
local6: .res 1
local7: .res 1
local8: .res 1
local9: .res 1
local10: .res 1
local11: .res 1
local12: .res 1
local13: .res 1
local14: .res 1
local15: .res 1

;; Array of 2*RENDER_COLUMN_HEIGHT (RCH, for short) bytes
;; containing the tiles for the two
;; columns that will be rendered on the next frame.
;; the first RCH elements represent the first column,
;; and the last RCH elements represent the second column.

;; this is stored in zero page because it is heavily accessed
;; during vblank, in which we don't have a lot of cycles.
;; NOTE: this was originally 60, but got reduced to this value
;;       if things related to this break, please update it to 60
render_columns: .res (2 * RENDER_COLUMN_HEIGHT)


.bss

;; bool, whether the program is currently runnning update code or not.
;; 0 if an update is not running (and it is ok for a render to run).
;; 1 if update code is/should be running (NMI code should rti immediately)
is_updating: .res 1

;; 0 when the program is doing the initial render of the tiles
;; 1 when the program is already rendering the algorithm steps
;; 2 when the program is done with the algorithm
current_sorting_stage: .res 1

;; The rng_seed for the random number generation
rng_seed: .res 2

;; The on-screen indexes of the columns that must be rendered
;; -1 means don't render anything
render_columns_positions: .res 2

;; The controller input value
controller_value: .res 8


;; Initial stage variables:

;; The index of the next two consecutive elements to process
init_stage_index: .res 1

;; Coroutine variables:
coroutine_started: .res 1
coroutine_s_register: .res 1
coroutine_local0: .res 8

;; Page aligned arrays :
.align 256

;; The numbers to be sorted
;; 128 bytes
sorting_array: .res 128
aux_array: .res 128

.align 256

;; The coroutine stack
coroutine_stack_start: .res 256

;; Exports

.export local0
.export local1
.export local2
.export local3
.export local4
.export local5
.export local6
.export local7
.export local8
.export local9
.export local10
.export local11
.export local12
.export local13
.export local14
.export local15

.export render_columns

.export is_updating
.export current_sorting_stage
.export rng_seed
.export render_columns_positions
.export init_stage_index
.export controller_value

.export coroutine_started
.export coroutine_s_register
.export coroutine_local0

.export sorting_array
.export aux_array
.export coroutine_stack_start
