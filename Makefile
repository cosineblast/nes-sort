
TARGETS = build/main.o \
	build/RootScene.o \
	build/MenuScene.o \
	build/SortSetupScene.o \
	build/columns.o \
	build/rng.o \
	build/SortScene.o \
	build/insertion_sort.o \
	build/heap_sort.o \
	build/coroutine.o \
	build/vars.o \
	build/input.o

all: build/sort.nes

clean:
	rm -rf build

build/%.o: src/%.s 
	@mkdir -p build
	ca65 $^ -o $@

build/sort.nes: $(TARGETS)
	ld65 $^ -o $@ --config linker_config.cfg

.PHONY: all clean
	
# See https://www.gnu.org/software/make/manual/html_node/Combine-By-Prerequisite.html
# for more details on this syntax
$(TARGETS) :
