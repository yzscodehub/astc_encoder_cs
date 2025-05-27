# ASTC Encoder Metal

使用Metal计算着色器实时压缩ASTC纹理，实现的是ASTC的一个子集。这是原始DirectX 11版本编码器的Metal移植版本。

## 功能特性

- 实时纹理压缩
- 支持ASTC 4x4模式
- 支持ASTC 6x6模式
- 支持Alpha通道
- 支持法线贴图
- 支持在线性或sRGB色彩空间中压缩

## 依赖

- [Metal](https://developer.apple.com/metal/) - 苹果的低级图形和计算API
- [MetalKit](https://developer.apple.com/documentation/metalkit) - Metal的辅助工具集
- [stb_image.h](https://github.com/nothings/stb/blob/master/stb_image.h) - 用于图像加载

## 编译

### 使用CMake构建（推荐）

详细的构建说明请参阅 [BUILD.md](BUILD.md) 文件。

```bash
# 创建构建目录
mkdir build && cd build

# 配置和构建
cmake ..
cmake --build .
```

### 使用Makefile构建（兼容旧版本）

```bash
make
```

## 使用方法

```bash
./astc_encoder_metal input_texture [选项参数]
```

| 命令参数 | 说明                        |
|---------|----------------------------|
| -4x4    | 使用ASTC 4x4格式，未指定则默认此选项 |
| -6x6    | 使用ASTC 6x6格式             |
| -alpha  | 包含Alpha通道处理            |
| -norm   | 作为法线贴图处理             |
| -srgb   | 在sRGB色彩空间中编码        |

### 示例

```bash
./astc_encoder_metal ./textures/leaf.png -alpha -4x4 -srgb
```

## 与DirectX版本的区别

本移植版本使用了Metal框架代替DirectX 11，主要修改包括：

1. 使用Objective-C++(.mm)实现Metal API调用
2. HLSL着色器代码移植到Metal着色器语言
3. 使用Metal的计算管线执行ASTC压缩
4. 使用Metal的缓冲区和纹理管理API

## 性能

Metal版本通常在Mac平台上提供与DirectX版本相当或更好的性能，特别是在Apple Silicon芯片上。

## 构建系统

项目支持两种构建系统：

1. **CMake** - 现代的跨平台构建系统，提供更灵活的配置选项和更好的IDE集成
2. **Makefile** - 简单的传统构建方式，适合快速编译 