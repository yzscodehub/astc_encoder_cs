#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <iostream>
#include "astc_encode_metal.h"

// 编译Metal着色器函数
static id<MTLFunction> compileShader(id<MTLDevice> device, NSString* shaderFilePath, NSString* entryPoint, const EncodeOption& option) {
    if (!device || !shaderFilePath || !entryPoint) {
        return nil;
    }
    
    NSError* error = nil;
    
    // 加载Metal文件
    NSString* shaderSource = [NSString stringWithContentsOfFile:shaderFilePath 
                                                      encoding:NSUTF8StringEncoding 
                                                         error:&error];
    if (error) {
        std::cerr << "Error loading shader file: " << [error.localizedDescription UTF8String] << std::endl;
        return nil;
    }
    
    // 创建编译选项
    MTLCompileOptions* compileOptions = [[MTLCompileOptions alloc] init];
    compileOptions.fastMathEnabled = YES;
    
    // 添加预处理器宏
    NSMutableDictionary* preprocessorMacros = [NSMutableDictionary dictionary];
    [preprocessorMacros setObject:@(THREAD_NUM_X) forKey:@"THREAD_NUM_X"];
    [preprocessorMacros setObject:@(THREAD_NUM_Y) forKey:@"THREAD_NUM_Y"];
    [preprocessorMacros setObject:@(option.isNormalMap ? 1 : 0) forKey:@"IS_NORMALMAP"];
    [preprocessorMacros setObject:@(option.is4x4 ? 0 : 1) forKey:@"BLOCK_6X6"];
    [preprocessorMacros setObject:@(option.hasAlpha ? 1 : 0) forKey:@"HAS_ALPHA"];
    compileOptions.preprocessorMacros = preprocessorMacros;
    
    // 从源代码创建库
    id<MTLLibrary> library = [device newLibraryWithSource:shaderSource
                                                 options:compileOptions
                                                   error:&error];
    if (error || !library) {
        std::cerr << "Error compiling shader: " << [error.localizedDescription UTF8String] << std::endl;
        return nil;
    }
    
    // 获取计算函数
    id<MTLFunction> function = [library newFunctionWithName:entryPoint];
    if (!function) {
        std::cerr << "Failed to find function " << [entryPoint UTF8String] << " in library" << std::endl;
    }
    
    return function;
}

id<MTLBuffer> encodeAstc(id<MTLDevice> device, id<MTLCommandQueue> commandQueue, id<MTLTexture> srcTexture, const EncodeOption& option) {
    // 获取Metal着色器函数
    id<MTLFunction> computeFunction = compileShader(device, 
                                                   @"ASTC_Encode.metal", 
                                                   @"MainCS", 
                                                   option);
    if (!computeFunction) {
        std::cerr << "Failed to load compute shader" << std::endl;
        return nil;
    }
    
    // 创建计算管线
    NSError* error = nil;
    id<MTLComputePipelineState> computePipeline = [device newComputePipelineStateWithFunction:computeFunction 
                                                                                      error:&error];
    if (error || !computePipeline) {
        std::cerr << "Failed to create compute pipeline: " << [error.localizedDescription UTF8String] << std::endl;
        return nil;
    }
    
    // 获取纹理尺寸
    int texWidth = (int)srcTexture.width;
    int texHeight = (int)srcTexture.height;
    
    // 计算块尺寸和数量
    int dimSize = option.is4x4 ? 4 : 6;
    int xBlockNum = (texWidth + dimSize - 1) / dimSize;
    int yBlockNum = (texHeight + dimSize - 1) / dimSize;
    int totalBlockNum = xBlockNum * yBlockNum;
    
    int groupSize = THREAD_NUM_X * THREAD_NUM_Y;
    int groupNum = (totalBlockNum + groupSize - 1) / groupSize;
    int groupNumX = (texWidth + dimSize - 1) / dimSize;
    int groupNumY = (groupNum + groupNumX - 1) / groupNumX;
    
    // 创建输出缓冲区
    NSUInteger bufferSize = BLOCK_BYTES * totalBlockNum;
    id<MTLBuffer> outputBuffer = [device newBufferWithLength:bufferSize 
                                                    options:MTLResourceStorageModeShared];
    
    // 创建常量缓冲区
    CSConstantBuffer constants;
    constants.InTexelHeight = texHeight;
    constants.InTexelWidth = texWidth;
    constants.InGroupNumX = groupNumX;
    constants.padding = 0;
    
    id<MTLBuffer> constantBuffer = [device newBufferWithBytes:&constants
                                                      length:sizeof(CSConstantBuffer)
                                                     options:MTLResourceStorageModeShared];
    
    // 创建命令缓冲区并编码
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    // 设置计算管线
    [computeEncoder setComputePipelineState:computePipeline];
    
    // 设置纹理
    [computeEncoder setTexture:srcTexture atIndex:0];
    
    // 设置缓冲区
    [computeEncoder setBuffer:outputBuffer offset:0 atIndex:0];
    [computeEncoder setBuffer:constantBuffer offset:0 atIndex:1];
    
    // 分配线程组
    MTLSize threadgroupSize = MTLSizeMake(THREAD_NUM_X, THREAD_NUM_Y, 1);
    MTLSize gridSize = MTLSizeMake(groupNumX, groupNumY, 1);
    [computeEncoder dispatchThreadgroups:gridSize threadsPerThreadgroup:threadgroupSize];
    [computeEncoder endEncoding];
    
    // 提交命令缓冲区并等待完成
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    return outputBuffer;
} 