##
# Project Title
#
# @file
# @version 0.1

rom: build/sort.nes

build/sort.nes: *.s linker_config.cfg Makefile
	cl65 main.s columns.s rng.s sort.s coroutine.s vars.s \
		--config linker_config.cfg \
		-o build/sort.nes --target nes --verbose



# end
