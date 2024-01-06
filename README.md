
# nessiesort

This project consists of a sorting algorithm visualizer, implemented for the
Nintendo Entertainement System.
It is inspired by [existing visualizations](https://www.youtube.com/watch?v=vr5dCRHAgb)
in video format.

Supported Algorithms:
- Insertion Sort
- Heap Sort

## building the project

After installing [cc65](https://cc65.github.io/),
running `make` will generate nes ROM in `build/sort.nes`.

### building with nix

If you have nix installed (and flakes enabled) , you can use `nix develop` to quickly setup
with the development tools.

### running the project

You can use your favorite NES emulator to try it out,
however, this project has limitations that make it possibly
unable to run on real hardward. See the implementation section for mor details>

## implementation

This project is written in 6502 assembly.
I've considered using `cc65`'s C compiler, but I was not
satisifed with the generated assembly code and the artificial stack employed.
I do however consider implementing non performance critical portions of it in another language,
either with `cc65`'s compiler, or [llvm-mos](`https://llvm-mos.org/wiki/Welcome`), since
I like the generated 6502 code.

The ROM's pattern table is generated with the script `gen.clj`, and are designed so
that each 8-bit column represents two values (which go up to 128), so there are
4 * 4 = 16 possible tiles.

The SHA256 of the pattern table is: d41b5222260ed17fa8c01258eaefc7ecd34f528150b6974dc83d48a35fabbc8a.

## coroutine mechamism

Considering the sorting algorithm has to be [re-entrant](https://en.wikipedia.org/wiki/Reentrancy_(computing))
(the algorithm must stop when a frame is to be rendered), the project implements a simple stackful asymetric
coroutine mechanism (see `coroutine.s`) , which simply copies the stack and
pseudoregisters to a spare location, when going into and leaving the coroutine.

### potential issues on real hardware

Despite working well with emulators, I am not confident this project works well with
real hardware, because testing the ROM with randomly initialized memory yields
bad graphics overall.

My program initializes RAM to zero before doing its things, so I suspect the culpirit
is the fact I don't initialize PPU's CGRAM, which
was implemented in [FCEUX](https://www.emunations.com/updates/fceux) since version
2.6.6.

This happens with other NES projects of mine as well.

## using the ROM

Currently, there is no mechanism for selecting which sorting algorithm you want to use,
you have to modify `sort.s` by changing the section in the code indicated by a comment.

Currently implemented algoriths (and their respective symbols) are `insertion_sort` and `heap_sort`.

The array is actually twice the size of the renderable screen,
so one can change the rendered portion of the screen using the controller.

# acknowledgements

- Ryan (aka [NESHacker](https://www.youtube.com/@NesHacker)) for his incredible content.
- The [NESDev wiki](https://www.nesdev.org/wiki/Nesdev_Wiki) for their wonderful, wonderful resources.
- cc65 for the awesome tools.

# license

The project is licensed under the 0BSD clause:


> Copyright (C) 2024 by Renan Ribeiro
>
> Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
>
> THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

