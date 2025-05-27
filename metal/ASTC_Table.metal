#ifndef ASTC_TABLE_METAL
#define ASTC_TABLE_METAL

/**
 * These quantization tables are copied from ARM's ASTC encoder:
 * https://github.com/ARM-software/astc-encoder/blob/34900c9ed16e9aafbf0b9f02979fe737edcc9958/Source/astc_quantization.cpp
 */
constant int quantization_table[] = {
    0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
    0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
    0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
    32,      64,      0,       0,       0,       0,       0,       0,       0,       0,
    5,       32,      64,      0,       0,       0,       0,       0,       0,       0,
    2,       8,       16,      32,      64,      0,       0,       0,       0,       0,
    2,       5,       8,       16,      32,      64,      0,       0,       0,       0,
    0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
    0,       0,       0,       0,       0,       0,       0,       0,       0,       0,
    0,       0,       0,       0,       0,       0,       0,       0,       0,       0
};

// from [ARM:astc-encoder] quantization_and_transfer_table quant_and_xfer_tables
#define WEIGHT_QUANTIZE_NUM 32
constant int scramble_table[12 * WEIGHT_QUANTIZE_NUM] = {
    // quantization method 0, range 0..1
    //{
        0, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 1, range 0..2
    //{
        0, 1, 2,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 2, range 0..3
    //{
        0, 1, 2, 3,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 3, range 0..4
    //{
        0, 1, 2, 3, 4,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 4, range 0..5
    //{
        0, 2, 4, 5, 3, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 5, range 0..7
    //{
        0, 1, 2, 3, 4, 5, 6, 7,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 6, range 0..9
    //{
        0, 2, 4, 6, 8, 9, 7, 5, 3, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 7, range 0..11
    //{
        0, 4, 8, 2, 6, 10, 11, 7, 3, 9, 5, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 8, range 0..15
    //{
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 9, range 0..19
    //{
        0, 4, 8, 12, 16, 2, 6, 10, 14, 18, 19, 15, 11, 7, 3, 17, 13, 9, 5, 1,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 10, range 0..23
    //{
        0, 8, 16, 2, 10, 18, 4, 12, 20, 6, 14, 22, 23, 15, 7, 21, 13, 5, 19,
        11, 3, 17, 9, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    //},
    // quantization method 11, range 0..31
    //{
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    //}
};

constant int color_component_precision[] = { 
    8, // QUANT_2
    7, // QUANT_3
    6, // QUANT_4
    5, // QUANT_5
    5, // QUANT_6
    4, // QUANT_8
    4, // QUANT_10
    4, // QUANT_12
    4, // QUANT_16
    4, // QUANT_20
    4, // QUANT_24
    3, // QUANT_32
    3, // QUANT_40
    3, // QUANT_48
    3, // QUANT_64
    2, // QUANT_80
    2, // QUANT_96
    2, // QUANT_128
    2, // QUANT_160
    2, // QUANT_192
    2  // QUANT_256
};

#endif 