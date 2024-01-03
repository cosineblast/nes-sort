##
# Project Title
#
# @file
# @version 0.1

rom: build/sort.nes

build/sort.nes: *.s
	cl65 main.s columns.s rng.s sort.s coroutine.s -o build/sort.nes --target nes --verbose



# end
