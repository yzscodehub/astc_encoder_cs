CC = clang++
CFLAGS = -std=c++17 -O3 -Wall -fobjc-arc
FRAMEWORKS = -framework Foundation -framework Metal -framework MetalKit

TARGET = astc_encoder_metal
SOURCES = main_metal.mm astc_encode_metal.mm
HEADERS = astc_encode_metal.h astc_save.h stb_image.h
METAL_SOURCES = ASTC_Encode.metal ASTC_Table.metal ASTC_IntegerSequenceEncoding.metal

all: $(TARGET)

$(TARGET): $(SOURCES) $(HEADERS) $(METAL_SOURCES)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(TARGET) $(SOURCES)
	# 复制Metal着色器到同一目录
	cp $(METAL_SOURCES) .

clean:
	rm -f $(TARGET)

.PHONY: all clean 