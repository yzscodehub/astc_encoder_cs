# Metal ASTC 编码器构建指南

本文档说明如何使用CMake构建Metal版本的ASTC纹理编码器。

## 先决条件

- macOS操作系统
- CMake 3.12或更高版本
- Xcode命令行工具或Xcode（包含clang++编译器）

## 构建步骤

### 1. 安装依赖

确保已安装CMake和Xcode命令行工具:

```bash
# 安装Homebrew（如果尚未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装CMake
brew install cmake

# 安装Xcode命令行工具
xcode-select --install
```

### 2. 构建项目

```bash
# 创建构建目录
mkdir build
cd build

# 配置CMake项目
cmake ..

# 构建项目
cmake --build .
```

### 3. 运行程序

构建完成后，可执行文件将位于`build`目录中：

```bash
# 在构建目录中运行
./astc_encoder_metal ../textures/your_image.png [选项参数]
```

### 构建选项

可以通过传递选项给CMake来修改构建配置：

```bash
# 设置发布模式构建
cmake -DCMAKE_BUILD_TYPE=Release ..

# 安装到系统
cmake --build . --target install
```

## 故障排除

如果遇到问题，请确认：

1. 您使用的是macOS操作系统（Metal仅在macOS上可用）
2. 已正确安装所有依赖项
3. Metal着色器文件（.metal）与可执行文件位于同一目录

如果构建过程中遇到Metal着色器编译错误，请检查着色器代码中的语法错误。 