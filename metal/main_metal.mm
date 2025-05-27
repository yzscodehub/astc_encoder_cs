#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <iostream>
#include <string>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include "astc_encode_metal.h"
#include "astc_save_metal.h"

// 加载纹理函数
id<MTLTexture> load_tex(id<MTLDevice> device, const char* tex_path, bool bSRGB) {
    int xsize = 0;
    int ysize = 0;
    int components = 0;
    stbi_set_flip_vertically_on_load(1);
    stbi_uc* image = stbi_load(tex_path, &xsize, &ysize, &components, STBI_rgb_alpha);
    
    if (image == nullptr) {
        printf("Failed to load image %s\nReason: %s\n", tex_path, stbi_failure_reason());
        return nil;
    }
    
    // 创建MTLTexture描述符
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:
                                              bSRGB ? MTLPixelFormatRGBA8Unorm_sRGB : MTLPixelFormatRGBA8Unorm
                                              width:xsize
                                              height:ysize
                                              mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    
    // 创建纹理
    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
    
    // 将图像数据复制到纹理
    MTLRegion region = MTLRegionMake2D(0, 0, xsize, ysize);
    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:image
               bytesPerRow:xsize * 4];
    
    stbi_image_free(image);
    
    return texture;
}

// 从文件路径获取文件扩展名
std::string get_file_extension(const char* file_path) {
    const char* ext = strrchr(file_path, '.');
    if (ext != NULL) {
        return std::string(ext + 1);
    }
    return "";
}

// 删除文件扩展名
void strip_file_extension(std::string &file_path) {
    const char* str = file_path.c_str();
    char* ext = const_cast<char*>(strrchr(str, '.'));
    if (ext != nullptr) {
        *ext = 0;
        file_path = str;
    }
}

// 解析命令行参数
bool parse_cmd(int argc, char** argv, EncodeOption& option) {
    auto func_arg_value = [](int index, int argc, char** argv, bool &ret) -> bool {
        if (index < argc && *(argv[index]) == '-') {
            ret = true;
            return true;
        }
        return false;
    };
    
    for (int i = 2; i < argc; ++i) {
        if (argv[i] == std::string("-4x4")) {
            if (!func_arg_value(i, argc, argv, option.is4x4)) {
                return false;
            }
        }
        else if (argv[i] == std::string("-6x6")) {
            if (!func_arg_value(i, argc, argv, option.is6x6)) {
                return false;
            }
        }
        else if (argv[i] == std::string("-norm")) {
            if (!func_arg_value(i, argc, argv, option.isNormalMap)) {
                return false;
            }
        }
        else if (argv[i] == std::string("-srgb")) {
            if (!func_arg_value(i, argc, argv, option.srgb)) {
                return false;
            }
        }
        else if (argv[i] == std::string("-alpha")) {
            if (!func_arg_value(i, argc, argv, option.hasAlpha)) {
                return false;
            }
        }
    }
    return true;
}

int main(int argc, char** argv) {
    // if (argc < 2) {
    //     std::cout << "wrong args count" << std::endl;
    //     return -1;
    // }
    
    // EncodeOption option;
    // if (!parse_cmd(argc, argv, option)) {
    //     std::cout << "wrong args options" << std::endl;
    //     return -1;
    // }

    EncodeOption option;
    option.hasAlpha = true;
    option.is4x4 = false;
    option.is6x6 = true;
    option.isNormalMap = false;
    option.srgb = false;
    
    std::cout << "encode option setting:\n"
        << "has_alpha\t" << std::boolalpha << option.hasAlpha << std::endl
        << "is 4x4 block\t" << option.is4x4 << std::endl
        << "normal map\t" << option.isNormalMap << std::endl
        << "encode in gamma color space\t" << option.srgb << std::endl;
    
    // 获取默认Metal设备
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        std::cout << "Metal is not supported on this device" << std::endl;
        return -1;
    }
    
    // 创建命令队列
    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    
    // std::string src_tex = argv[1];
    std::string src_tex = "./4k.png";
    
    // 加载源纹理
    id<MTLTexture> pSrcTexture = load_tex(device, src_tex.c_str(), option.srgb && (!option.isNormalMap));
    if (pSrcTexture == nil) {
        std::cout << "load source texture failed! [" << src_tex << "]" << std::endl;
        return -1;
    }
    
    int TexWidth = (int)pSrcTexture.width;
    int TexHeight = (int)pSrcTexture.height;
    
    // 进行ASTC编码
    id<MTLBuffer> pOutBuf = encodeAstc(device, commandQueue, pSrcTexture, option);
    if (pOutBuf == nil) {
        std::cout << "encode astc failed!" << std::endl;
        return -1;
    }
    
    // 获取缓冲区大小
    uint32_t bufLen = (uint32_t)pOutBuf.length;
    uint8_t* pMemBuf = (uint8_t*)malloc(bufLen);
    if (!pMemBuf) {
        std::cout << "failed to allocate memory" << std::endl;
        return -1;
    }
    
    // 将GPU缓冲区数据复制到CPU内存
    memcpy(pMemBuf, pOutBuf.contents, bufLen);
    
    std::string dst_tex(src_tex);
    strip_file_extension(dst_tex);
    dst_tex += ".astc";
    
    // 保存ASTC文件
    int DimSize = option.is4x4 ? 4 : 6;
    save_astc(dst_tex.c_str(), DimSize, DimSize, TexWidth, TexHeight, pMemBuf, bufLen);
    
    free(pMemBuf);
    
    std::cout << "save astc to:" << dst_tex << std::endl;
    
    return 0;
} 