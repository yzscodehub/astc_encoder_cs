#pragma once

#include <cstdint>
#include <cstdio>

#define MAGIC_FILE_CONSTANT 0x5CA1AB13

// ASTC文件头结构
struct astc_header
{
    uint8_t magic[4];
    uint8_t blockdim_x;
    uint8_t blockdim_y;
    uint8_t blockdim_z;
    uint8_t xsize[3];           // x-size = xsize[0] + xsize[1] + xsize[2]
    uint8_t ysize[3];           // x-size, y-size and z-size are given in texels;
    uint8_t zsize[3];           // block count is inferred
};

/**
 * 保存ASTC压缩数据到文件
 * 
 * @param astc_path 输出文件路径
 * @param xdim X维度块大小（通常是4或6）
 * @param ydim Y维度块大小（通常是4或6） 
 * @param xsize 纹理宽度（像素）
 * @param ysize 纹理高度（像素）
 * @param buffer 压缩后的ASTC数据缓冲区
 * @param bufsz 缓冲区大小（字节）
 */
void save_astc(const char* astc_path, int xdim, int ydim, int xsize, int ysize, uint8_t* buffer, int bufsz)
{
    astc_header hdr;
    hdr.magic[0] = MAGIC_FILE_CONSTANT & 0xFF;
    hdr.magic[1] = (MAGIC_FILE_CONSTANT >> 8) & 0xFF;
    hdr.magic[2] = (MAGIC_FILE_CONSTANT >> 16) & 0xFF;
    hdr.magic[3] = (MAGIC_FILE_CONSTANT >> 24) & 0xFF;
    hdr.blockdim_x = xdim;
    hdr.blockdim_y = ydim;
    hdr.blockdim_z = 1;
    hdr.xsize[0] = xsize & 0xFF;
    hdr.xsize[1] = (xsize >> 8) & 0xFF;
    hdr.xsize[2] = (xsize >> 16) & 0xFF;
    hdr.ysize[0] = ysize & 0xFF;
    hdr.ysize[1] = (ysize >> 8) & 0xFF;
    hdr.ysize[2] = (ysize >> 16) & 0xFF;
    hdr.zsize[0] = 1;
    hdr.zsize[1] = 0;
    hdr.zsize[2] = 0;

    FILE *wf = fopen(astc_path, "wb");
    if (!wf) {
        printf("Error: Could not open file for writing: %s\n", astc_path);
        return;
    }
    
    fwrite(&hdr, 1, sizeof(astc_header), wf);
    fwrite(buffer, 1, bufsz, wf);
    fclose(wf);
} 