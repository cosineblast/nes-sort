import os

DOIT_CONFIG = {"default_tasks": ["compile"]}

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

def task_compile():
    sources = ' '.join(SOURCES)

    return {
        'targets': ['build/sort.nes'],
        'actions': [
            lambda targets: os.makedirs('build/', exist_ok=True),
            f"cl65 {sources} --config linker_config.cfg -o build/sort.nes --target nes --verbose" ]
    }

