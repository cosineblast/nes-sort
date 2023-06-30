
  ;; General Purpose zero page "registers"
  local0 = $01
  local1 = $02
  local2 = $03
  local3 = $04

  ;; Array of 2*RENDER_COLUMN_HEIGHT (60) bytes containing the tiles for the two
  ;; columns that will be rendered on the next frame.
  ;; first 30 elements represent the first column,
  ;; last 30  elements represet the second column.
  ;; $ff - 60
  render_columns = $c3


  ;; bool, whether the program is currently runnning update code or not.
  ;; 0 if an update is not running (and it is ok for a render to run).
  ;; 1 if update code is/should be running,
  is_updating = $0200

  ;; 0 when the program is doing the initial render of the tiles
  ;; 1 when the program is already rendering the algorithm steps
  ;; 2 when the program is done with the algorithm
  current_sorting_stage = $0201

  SORTING_STAGE_INIT = 0
  SORTING_STAGE_SORT = 1
  SORTING_STAGE_DONE = 2


  ;; The rng_seed for the random number generation
  ;; Two bytes
  rng_seed = $0202

  ;; The on-screen indexes of the columns that must be rendered
  ;; -1 means don't render anything
  ;; Two bytes, two numbers
  render_columns_positions = $0204

  NO_RENDER_COLUMN = $ff

  ;; Initial Stage Specific:

  ;; The index of the next two elements to process
  ;; One byte
  init_stage_index = $0206

  ;; The is the index of the element that is being inserted
  ;; by the current insertion of the sort
  insertion_sort_forward_index = $0207

  ;; This is the index of the element that we are comparing against
  ;; in the current insertion of the insertion sort
  insertion_sort_backward_index = $0208

  ;; One byte
  insertion_sort_has_started = $0209


  ;; The numbers to be sorted
  ;; 128 bytes
  sorting_array = $0300

  SORTING_DATA_SIZE = 127

  RENDER_COLUMN_HEIGHT = 26

  COLUMNS_PER_SCREEN = 32
