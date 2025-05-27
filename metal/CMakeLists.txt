cmake_minimum_required(VERSION 3.12)
project(astc_encoder_metal LANGUAGES CXX OBJCXX)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -Wall")
set(CMAKE_OBJCXX_FLAGS "${CMAKE_OBJCXX_FLAGS} -fobjc-arc")

# 查找需要的框架
find_library(FOUNDATION_LIBRARY Foundation REQUIRED)
find_library(METAL_LIBRARY Metal REQUIRED)
find_library(METALKIT_LIBRARY MetalKit REQUIRED)

# 源文件和头文件
set(SOURCES
    main_metal.mm
    astc_encode_metal.mm
)

set(HEADERS
    astc_encode_metal.h
    astc_save_metal.h
    stb_image.h
)

# Metal着色器文件
set(METAL_SOURCES
    ASTC_Encode.metal
    ASTC_Table.metal
    ASTC_IntegerSequenceEncoding.metal
)

# 添加可执行文件
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

# 链接框架
target_link_libraries(${PROJECT_NAME} PRIVATE
    ${FOUNDATION_LIBRARY}
    ${METAL_LIBRARY}
    ${METALKIT_LIBRARY}
)

# 复制Metal着色器文件到构建目录
foreach(metal_file ${METAL_SOURCES})
    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
                ${CMAKE_SOURCE_DIR}/${metal_file}
                ${CMAKE_CURRENT_BINARY_DIR}/${metal_file}
        COMMENT "Copying ${metal_file} to build directory"
    )
endforeach()

# 安装目标
install(TARGETS ${PROJECT_NAME} DESTINATION bin) 