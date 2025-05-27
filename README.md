# ASTC Encoder CS

基于计算着色器的高性能 ASTC (Adaptive Scalable Texture Compression) 纹理编码器。该项目提供了 DirectX 和 Metal 两个版本的实现，利用 GPU 并行计算能力，提供快速的纹理压缩功能。

## 功能特性

- 支持 ASTC 4x4 和 6x6 块压缩格式
- 提供 DirectX 和 Metal 两个版本的实现
- 利用计算着色器进行 GPU 加速
- 支持普通纹理和法线贴图编码
- 支持 sRGB 和线性色彩空间
- 支持带 Alpha 通道的纹理压缩

## DirectX 版本

### 系统要求
- Windows 操作系统
- 支持 DirectX 11 的 GPU
- Visual Studio 开发环境

### 构建说明
1. 使用 Visual Studio 打开 `dx/astc_cs_enc.sln`
2. 选择目标平台和配置
3. 构建解决方案

## Metal 版本

### 系统要求
- macOS 操作系统
- 支持 Metal API 的 GPU
- Xcode 开发环境

### 构建说明
1. 使用 Xcode 打开项目并构建

## 使用方法

命令行参数：

```bash
./astc_encoder [input_texture] [options]
```

### 可选参数

- `-4x4`: 使用 4x4 块压缩（默认）
- `-6x6`: 使用 6x6 块压缩
- `-norm`: 法线贴图模式
- `-srgb`: 在 sRGB 色彩空间中编码
- `-alpha`: 包含 Alpha 通道

### 示例

```bash
# 压缩普通纹理（4x4 块）
./astc_encoder input.png -4x4

# 压缩带 Alpha 通道的纹理（6x6 块）
./astc_encoder input.png -6x6 -alpha

# 压缩法线贴图
./astc_encoder normal.png -norm
```

## 项目结构

- `dx/`: DirectX 实现代码
  - `ASTC_Encode.hlsl`: DirectX 计算着色器实现
  - `main.cpp`: DirectX 版本主程序
- `metal/`: Metal 实现代码
  - `ASTC_Encode.metal`: Metal 计算着色器实现
  - `main_metal.mm`: Metal 版本主程序
- `textures/`: 测试用纹理文件
- `build/`: 构建输出目录

## 许可证

本项目基于 LICENSE 文件中指定的许可条款进行分发。

## 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进项目。

## 致谢

- 感谢 ARM 提供的 ASTC 编码器参考实现
- 感谢所有为项目做出贡献的开发者 