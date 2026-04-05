import struct
from functools import reduce

def transpose(matrix):
    return list(zip(*matrix))

def generate_tile(x, y):
    left = ([0] * (2 * (4 - x))) + ([1] * (2 * x))
    right = ([0] * (2 * (4 - y))) + ([1] * (2 * y))
    
    transposed = ([left] * 4) + ([right] * 4)
    
    matrix = transpose(transposed)

    return [pixel for row in matrix for pixel in row]

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

def main():
    all_tiles = [generate_tile(i, j) for i in range(5) for j in range(5)]
    pattern_table = [entry for tile in all_tiles for entry in tile_to_word(tile)]
        
    with open("pattern-table.bin", "wb") as file:
        for byte in pattern_table:
            file.write(struct.pack('1B', byte))
   

if __name__ == "__main__":
    main()
