##
# Project Title
#
# @file
# @version 0.1

rom: build/sort.nes

build/sort.nes: columns.s rng.s main.s
	cl65 $^ -o build/sort.nes --target nes --verbose



# end
