
all: build/sort.nes

clean:
	$(RM) *.o

SOURCES=src/main.s \
		src/init_stage.s \
		src/columns.s  \
		src/rng.s \
		src/sort.s \
		src/insertion_sort.s \
		src/heap_sort.s \
		src/coroutine.s \
		src/vars.s \
		src/input.s \

build/sort.nes: $(SOURCES) linker_config.cfg Makefile
	mkdir -p build
	cl65 $(SOURCES) \
		--config linker_config.cfg \
		-o build/sort.nes --target nes --verbose

