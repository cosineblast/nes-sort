import os
from pathlib import Path

from doit.tools import create_folder

DOIT_CONFIG = {"default_tasks": ["compile_rom"]}
mkdir = (create_folder, ['build'])


SOURCES = [
    "src/main.s",
    "src/init_stage.s",
    "src/columns.s",
    "src/rng.s",
    "src/sort.s",
    "src/insertion_sort.s",
    "src/heap_sort.s",
    "src/coroutine.s",
    "src/vars.s",
    "src/input.s",
]

def output_name(source):
    # 'src/main.s' -> 'build/main.o'
    return Path('build') / (Path(source).stem + '.o')

def task_compile_asm():
    """Compile assembly source files to object files"""
    for source in SOURCES:
        output = output_name(source)
        yield {
                'name': f'{source}',
                'file_dep': [source],
                'targets': [output],
                'actions': [mkdir,
                            f'ca65 {source} -o {output}'],
                'verbosity': 2

        }


def task_compile_rom():
    """Compile iNES ROM"""
    return {
            'file_dep': [output_name(source) for source in SOURCES],
            'targets': ['build/sort.nes'],
            'actions': [f'ld65 %(dependencies)s -o %(targets)s --config linker_config.cfg']
    }

