import struct
from functools import reduce
import imageio.v3 as iio
import numpy as np

def transpose(matrix):
    return list(zip(*matrix))

def flatten(rows):
    return [element for row in rows for element in row]

def generate_tile(x, y):
    left = ([0] * (2 * (4 - x))) + ([1] * (2 * x))
    right = ([0] * (2 * (4 - y))) + ([2] * (2 * y))
    
    transposed = ([left] * 4) + ([right] * 4)
    
    matrix = transpose(transposed)

    return flatten(matrix)

def row_to_byte(row):
    return reduce((lambda acc, bit: (acc << 1) | bit), row, 0)

def tile_to_word(tile):
    left_bits = [(p & 0x1) for p in tile]
    right_bits = [((p & 0x2) >> 1) for p in tile]
    
    output = []
    for bits in [left_bits, right_bits]:
        for i in range(0, 64, 8):
            row = bits[i : i + 8]
            output.append(row_to_byte(row))
            
    return output

def read_alphabet():
    image = iio.imread('chars.bmp').astype(np.float32).mean(axis=-1) / 255.0

    assert image.shape[0] == 8
    assert image.shape[1] % 8 == 0

    alphabet = []

    for i in range(0,(image.shape[1] // 8)):
        start = i * 8
        end = (i + 1) * 8
        thing = (image[:, start:end] > 0.5).astype(np.int8)
        alphabet.append(flatten(thing))

    return alphabet

    

def main():
    all_tiles = [generate_tile(i, j) for i in range(5) for j in range(5)]
    pattern_table = flatten(map(tile_to_word, all_tiles))
        
    with open("pattern-table.bin", "wb") as file:
        for byte in pattern_table:
            file.write(struct.pack('1B', byte))

    alphabet = read_alphabet()
    alphabet_table = [entry for tile in alphabet for entry in tile_to_word(tile)]

    with open('alphabet-table.bin', 'wb') as file:
        for byte in alphabet_table:
            file.write(struct.pack('1B', byte))

            

   

if __name__ == "__main__":
    main()
