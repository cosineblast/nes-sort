##
# Project Title
#
# @file
# @version 0.1

rom: build/sort.nes

build/sort.nes: main.s
	cl65 main.s rng.s -o build/sort.nes --target nes --verbose



# end
