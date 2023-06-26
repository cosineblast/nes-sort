##
# Project Title
#
# @file
# @version 0.1

rom: build/sort.nes

build/sort.nes: *.s
	cl65 columns.s rng.s main.s -o build/sort.nes --target nes --verbose



# end
