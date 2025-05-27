#pragma once

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <simd/simd.h>

#define THREAD_NUM_X    8
#define THREAD_NUM_Y    8
#define BLOCK_BYTES     16

// 编码选项结构体
struct EncodeOption {
    bool is4x4;
    bool is6x6;
    bool isNormalMap;
    bool hasAlpha;
    bool srgb;
    
    EncodeOption() : is4x4(true),
                    is6x6(false),
                    isNormalMap(false),
                    hasAlpha(false),
                    srgb(false) {}
};

// 计算着色器使用的常量缓冲区
struct CSConstantBuffer {
    uint32_t InTexelHeight;
    uint32_t InTexelWidth;
    uint32_t InGroupNumX;
    uint32_t padding; // 保持16字节对齐
};

// 编码ASTC纹理的主函数
id<MTLBuffer> encodeAstc(id<MTLDevice> device, id<MTLCommandQueue> commandQueue, id<MTLTexture> srcTexture, const EncodeOption& option); 