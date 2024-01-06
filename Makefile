##
# Project Title
#
# @file
# @version 0.1

rom: build/sort.nes

build/sort.nes: *.s linker_config.cfg Makefile
	mkdir -p build
	cl65 main.s \
		init_stage.s \
		columns.s rng.s \
		sort.s insertion_sort.s heap_sort.s \
		coroutine.s vars.s input.s \
		--config linker_config.cfg \
		-o build/sort.nes --target nes --verbose



# end
