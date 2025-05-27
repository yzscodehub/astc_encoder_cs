#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

#ifndef THREAD_NUM_X
#define THREAD_NUM_X 8
#endif

#ifndef THREAD_NUM_Y
#define THREAD_NUM_Y 8
#endif

#ifndef BLOCK_6X6
#define BLOCK_6X6 0
#endif

#ifndef HAS_ALPHA
#define HAS_ALPHA 0
#endif

#ifndef IS_NORMALMAP
#define IS_NORMALMAP 0
#endif

#if BLOCK_6X6
#define DIM 6
#else
#define DIM 4
#endif

#define BLOCK_SIZE ((DIM) * (DIM))

#define BLOCK_BYTES 16

#define X_GRIDS 4
#define Y_GRIDS 4

#define SMALL_VALUE 0.00001

/*
* supported color_endpoint_mode
*/
#define CEM_LDR_RGB_DIRECT 8
#define CEM_LDR_RGBA_DIRECT 12

/**
 * from [ARM:astc-encoder]
 * Define normalized (starting at zero) numeric ranges that can be represented
 * with 8 bits or less.
 */
#define QUANT_2 0
#define QUANT_3 1
#define QUANT_4 2
#define QUANT_5 3
#define QUANT_6 4
#define QUANT_8 5
#define QUANT_10 6
#define QUANT_12 7
#define QUANT_16 8
#define QUANT_20 9
#define QUANT_24 10
#define QUANT_32 11
#define QUANT_40 12
#define QUANT_48 13
#define QUANT_64 14
#define QUANT_80 15
#define QUANT_96 16
#define QUANT_128 17
#define QUANT_160 18
#define QUANT_192 19
#define QUANT_256 20
#define QUANT_MAX 21

#include "ASTC_Table.metal"
#include "ASTC_IntegerSequenceEncoding.metal"

struct CSConstant {
    uint InTexelHeight;
    uint InTexelWidth;
    uint InGroupNumX;
    uint padding;
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// calc the dominant axis
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void swap(thread float4& lhs, thread float4& rhs)
{
    float4 tmp = lhs;
    lhs = rhs;
    rhs = tmp;
}

float4 eigen_vector(float4x4 m)
{
    // calc the max eigen value by iteration
    float4 v = float4(0.26726f, 0.80178f, 0.53452f, 0.0f);
    for (int i = 0; i < 8; ++i)
    {
        v = m * v;
        if (length(v) < SMALL_VALUE) {
            return v;
        }
        v = normalize(m * v);
    }
    return v;
}

void find_min_max(thread float4* texels, float4 pt_mean, float4 vec_k, thread float4& e0, thread float4& e1)
{
    float a = 1e31f;
    float b = -1e31f;
    for (int i = 0; i < BLOCK_SIZE; ++i)
    {
        float4 texel = texels[i] - pt_mean;
        float t = dot(texel, vec_k);
        a = min(a, t);
        b = max(b, t);
    }

    e0 = clamp(vec_k * a + pt_mean, 0.0f, 255.0f);
    e1 = clamp(vec_k * b + pt_mean, 0.0f, 255.0f);

    // if the direction-vector ends up pointing from light to dark, FLIP IT!
    // this will make the first endpoint the darkest one.
    float4 e0u = round(e0);
    float4 e1u = round(e1);
    if (e0u.x + e0u.y + e0u.z > e1u.x + e1u.y + e1u.z)
    {
        swap(e0, e1);
    }

#if !HAS_ALPHA
    e0.a = 255.0f;
    e1.a = 255.0f;
#endif
}

void principal_component_analysis(thread float4* texels, thread float4& e0, thread float4& e1)
{
    int i = 0;
    float4 pt_mean = 0;
    for (i = 0; i < BLOCK_SIZE; ++i)
    {
        pt_mean += texels[i];
    }
    pt_mean /= BLOCK_SIZE;

    float4x4 cov = float4x4(0.0f);
    float s = 0;
    for (int k = 0; k < BLOCK_SIZE; ++k)
    {
        float4 texel = texels[k] - pt_mean;
        for (i = 0; i < 4; ++i)
        {
            for (int j = 0; j < 4; ++j)
            {
                cov[i][j] += texel[i] * texel[j];
            }
        }
    }
    cov /= BLOCK_SIZE - 1;

    float4 vec_k = eigen_vector(cov);

    find_min_max(texels, pt_mean, vec_k, e0, e1);
}

void max_accumulation_pixel_direction(thread float4* texels, thread float4& e0, thread float4& e1)
{
    int i = 0;
    float4 pt_mean = 0;
    for (i = 0; i < BLOCK_SIZE; ++i)
    {
        pt_mean += texels[i];
    }
    pt_mean /= BLOCK_SIZE;

    float4 sum_r = float4(0,0,0,0);
    float4 sum_g = float4(0,0,0,0);
    float4 sum_b = float4(0,0,0,0);
    float4 sum_a = float4(0,0,0,0);
    for (i = 0; i < BLOCK_SIZE; ++i)
    {
        float4 dt = texels[i] - pt_mean;
        sum_r += (dt.x > 0) ? dt : 0;
        sum_g += (dt.y > 0) ? dt : 0;
        sum_b += (dt.z > 0) ? dt : 0;
        sum_a += (dt.w > 0) ? dt : 0;
    }

    float dot_r = dot(sum_r, sum_r);
    float dot_g = dot(sum_g, sum_g);
    float dot_b = dot(sum_b, sum_b);
    float dot_a = dot(sum_a, sum_a);

    float maxdot = dot_r;
    float4 vec_k = sum_r;

    if (dot_g > maxdot)
    {
        vec_k = sum_g;
        maxdot = dot_g;
    }

    if (dot_b > maxdot)
    {
        vec_k = sum_b;
        maxdot = dot_b;
    }

#if HAS_ALPHA
    if (dot_a > maxdot)
    {
        vec_k = sum_a;
        maxdot = dot_a;
    }
#endif

    // safe normalize
    float lenk = length(vec_k);
    vec_k = (lenk < SMALL_VALUE) ? vec_k : normalize(vec_k);

    find_min_max(texels, pt_mean, vec_k, e0, e1);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// quantize & unquantize the endpoints
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// for QUANT_256 quantization
void encode_color(uint qm_index, float4 e0, float4 e1, thread uint* endpoint_quantized)
{
    uint4 e0q = uint4(round(e0));
    uint4 e1q = uint4(round(e1));
    endpoint_quantized[0] = e0q.r;
    endpoint_quantized[1] = e1q.r;
    endpoint_quantized[2] = e0q.g;
    endpoint_quantized[3] = e1q.g;
    endpoint_quantized[4] = e0q.b;
    endpoint_quantized[5] = e1q.b;
    endpoint_quantized[6] = e0q.a;
    endpoint_quantized[7] = e1q.a;
}

void decode_color(uint qm_index, thread uint* endpoint_quantized, thread float4& e0, thread float4& e1)
{
    e0 = float4(endpoint_quantized[0], endpoint_quantized[2], endpoint_quantized[4], endpoint_quantized[6]);
    e1 = float4(endpoint_quantized[1], endpoint_quantized[3], endpoint_quantized[5], endpoint_quantized[7]);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate quantized weights
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
uint quantize_weight(uint weight_range, float weight)
{
    uint q = round(weight * weight_range);
    return clamp(q, 0u, weight_range);
}

float unquantize_weight(uint weight_range, uint qw)
{
    float w = 1.0 * qw / weight_range;
    return clamp(w, 0.0, 1.0);
}

constant uint4 idx_grids[16] = {
    uint4(0, 1, 6, 7),
    uint4(1, 2, 7, 8),
    uint4(3, 4, 9, 10),
    uint4(4, 5, 10, 11),
    uint4(6, 7, 12, 13),
    uint4(7, 8, 13, 14),
    uint4(9, 10, 15, 16),
    uint4(10, 11, 16, 17),
    uint4(18, 19, 24, 25),
    uint4(19, 20, 25, 26),
    uint4(21, 22, 27, 28),
    uint4(22, 23, 28, 29),
    uint4(24, 25, 30, 31),
    uint4(25, 26, 31, 32),
    uint4(27, 28, 33, 34),
    uint4(28, 29, 34, 35),
};

constant float4 wt_grids[16] = {
    float4(0.444, 0.222, 0.222, 0.111),
    float4(0.222, 0.444, 0.111, 0.222),
    float4(0.444, 0.222, 0.222, 0.111),
    float4(0.222, 0.444, 0.111, 0.222),
    float4(0.222, 0.111, 0.444, 0.222),
    float4(0.111, 0.222, 0.222, 0.444),
    float4(0.222, 0.111, 0.444, 0.222),
    float4(0.111, 0.222, 0.222, 0.444),
    float4(0.444, 0.222, 0.222, 0.111),
    float4(0.222, 0.444, 0.111, 0.222),
    float4(0.444, 0.222, 0.222, 0.111),
    float4(0.222, 0.444, 0.111, 0.222),
    float4(0.222, 0.111, 0.444, 0.222),
    float4(0.111, 0.222, 0.222, 0.444),
    float4(0.222, 0.111, 0.444, 0.222),
    float4(0.111, 0.222, 0.222, 0.444),
};

float4 sample_texel(thread float4* texels, uint4 index, float4 coff)
{
    float4 result = 0;
    result += texels[index[0]] * coff[0];
    result += texels[index[1]] * coff[1];
    result += texels[index[2]] * coff[2];
    result += texels[index[3]] * coff[3];
    return result;
}

// calc the error of a grid when reconstructing
float calc_grid_error(thread float4* texels, thread float4* recon_texels, uint4 v_idx)
{
    float error = 0;
    for (int i = 0; i < 4; ++i)
    {
        float4 c = texels[v_idx[i]] - recon_texels[v_idx[i]];
        error += dot(c.xyz, c.xyz);
    }
    return error;
}

// compute approximate line, sample linearly and calculate weights
void calculate_quantized_weights(thread float4* texels, uint weight_range, float4 e0, float4 e1, thread uint* weights)
{
    thread float weights_f[X_GRIDS * Y_GRIDS];
    
    // 计算weights
    for (int i = 0; i < Y_GRIDS; ++i)
    {
        for (int j = 0; j < X_GRIDS; ++j)
        {
            uint grid_idx = i * X_GRIDS + j;
            uint4 v_idx = idx_grids[grid_idx];
            float4 grid_texel = sample_texel(texels, v_idx, wt_grids[grid_idx]);
            
            // 在线性方向做投影
            float3 e0_rgb = e0.rgb;
            float3 e1_rgb = e1.rgb;
            float3 vec = e1_rgb - e0_rgb;
            
            float len = length(vec);
            float weight = 0.0;
            
            if (len > SMALL_VALUE)
            {
                float3 norm_vec = vec / len;
                float3 norm_texel = grid_texel.rgb - e0_rgb;
                float dt = dot(norm_texel, norm_vec);
                dt = clamp(dt, 0.0f, len);
                weight = dt / len;
            }
            
            weights_f[grid_idx] = weight;
        }
    }
    
    // 量化weights
    for (int i = 0; i < Y_GRIDS; ++i)
    {
        for (int j = 0; j < X_GRIDS; ++j)
        {
            uint grid_idx = i * X_GRIDS + j;
            
            weights[grid_idx] = quantize_weight(weight_range, weights_f[grid_idx]);
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// encode single partition
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// candidate blockmode uint4(weights quantmethod, endpoints quantmethod, weights range, endpoints quantmethod index of table)

uint4 assemble_block(uint blockmode, uint color_endpoint_mode, uint partition_count, uint partition_index, uint4 ep_ise, uint4 wt_ise)
{
    uint4 phy_blk = uint4(0, 0, 0, 0);
    
    // weights ise
    phy_blk.w |= reverse_byte(wt_ise.x & 0xFF) << 24;
    phy_blk.w |= reverse_byte((wt_ise.x >> 8) & 0xFF) << 16;
    phy_blk.w |= reverse_byte((wt_ise.x >> 16) & 0xFF) << 8;
    phy_blk.w |= reverse_byte((wt_ise.x >> 24) & 0xFF);

    phy_blk.z |= reverse_byte(wt_ise.y & 0xFF) << 24;
    phy_blk.z |= reverse_byte((wt_ise.y >> 8) & 0xFF) << 16;
    phy_blk.z |= reverse_byte((wt_ise.y >> 16) & 0xFF) << 8;
    phy_blk.z |= reverse_byte((wt_ise.y >> 24) & 0xFF);

    phy_blk.y |= reverse_byte(wt_ise.z & 0xFF) << 24;
    phy_blk.y |= reverse_byte((wt_ise.z >> 8) & 0xFF) << 16;
    phy_blk.y |= reverse_byte((wt_ise.z >> 16) & 0xFF) << 8;
    phy_blk.y |= reverse_byte((wt_ise.z >> 24) & 0xFF);

    // blockmode & partition count
    phy_blk.x = blockmode; // blockmode is 11 bit

    //if (partition_count > 1)
    //{
    //    uint endpoint_offset = 29;
    //    uint cem_bits = 6;
    //    uint bitpos = 13;
    //    orbits8_ptr(phy_blk, bitpos, partition_count - 1, 2);
    //    orbits8_ptr(phy_blk, bitpos, partition_index & 63, 6);
    //    orbits8_ptr(phy_blk, bitpos, partition_index >> 6, 4);
    //  ...
    //}

    // cem: color_endpoint_mode is 4 bit
    phy_blk.x |= (color_endpoint_mode & 0xF) << 13;

    // endpoints start from ( multi_part ? bits 29 : bits 17 )
    phy_blk.x |= (ep_ise.x & 0x7FFF) << 17;
    phy_blk.y = ((ep_ise.x >> 15) & 0x1FFFF);
    phy_blk.y |= (ep_ise.y & 0x7FFF) << 17;
    phy_blk.z |= ((ep_ise.y >> 15) & 0x1FFFF);

    return phy_blk;
}

uint assemble_blockmode(uint weight_quantmethod)
{
/*
    the first row of "Table C.2.8 - 2D Block Mode Layout".
    ------------------------------------------------------------------------
    10  9   8   7   6   5   4   3   2   1   0   Width Height Notes
    ------------------------------------------------------------------------
    D   H     B       A     R0  0   0   R2  R1  B + 4   A + 2
*/

    uint a = (Y_GRIDS - 2) & 0x3;
    uint b = (X_GRIDS - 4) & 0x3;

    uint d = 0;  // dual plane

    // more details from "Table C.2.7 - Weight Range Encodings"    
    uint h = (weight_quantmethod < 6) ? 0 : 1;    // "a precision bit H"
    uint r = (weight_quantmethod % 6) + 2;        // "The weight ranges are encoded using a 3 bit value R"

    // block mode
    uint blockmode = (r >> 1) & 0x3;
    blockmode |= (r & 0x1) << 4;
    blockmode |= (a & 0x3) << 5;
    blockmode |= (b & 0x3) << 7;
    blockmode |= h << 9;
    blockmode |= d << 10;
    return blockmode;
}

uint4 endpoint_ise(uint colorquant_index, float4 ep0, float4 ep1, uint endpoint_quantmethod)
{
    // encode endpoints
    uint ep_quantized[8];
    encode_color(colorquant_index, ep0, ep1, ep_quantized);
#if !HAS_ALPHA
    ep_quantized[6] = 0;
    ep_quantized[7] = 0;
#endif

    // endpoints quantized ise encode
    uint4 ep_ise = 0;
    bise_endpoints(ep_quantized, endpoint_quantmethod, ep_ise);
    return ep_ise;
}

uint4 weight_ise(thread float4* texels, uint weight_range, float4 ep0, float4 ep1, uint weight_quantmethod)
{
    int i = 0;
    // encode weights
    uint wt_quantized[X_GRIDS * Y_GRIDS];
    calculate_quantized_weights(texels, weight_range, ep0, ep1, wt_quantized);

    for (i = 0; i < X_GRIDS * Y_GRIDS; ++i)
    {
        int w = weight_quantmethod * WEIGHT_QUANTIZE_NUM + wt_quantized[i];
        wt_quantized[i] = scramble_table[w];
    }

    // weights quantized ise encode
    uint4 wt_ise = 0;
    bise_weights(wt_quantized, weight_quantmethod, wt_ise);
    return wt_ise;
}

uint4 encode_block(thread float4* texels)
{
    float4 ep0, ep1;
    principal_component_analysis(texels, ep0, ep1);
    //max_accumulation_pixel_direction(texels, ep0, ep1);

    // endpoints_quant是根据整个128bits减去weights的编码占用和其他配置占用后剩余的bits位数来确定的。
    // for fast compression!
#if HAS_ALPHA
    uint4 best_blockmode = uint4(QUANT_6, QUANT_256, 6, 7);
#else
    uint4 best_blockmode = uint4(QUANT_12, QUANT_256, 12, 7);
#endif

//#if !FAST
//    choose_best_quantmethod(texels, ep0, ep1, best_blockmode);
//#endif

    uint weight_quantmethod = best_blockmode.x;
    uint endpoint_quantmethod = best_blockmode.y;
    uint weight_range = best_blockmode.z;
    uint colorquant_index = best_blockmode.w;

    // reference to arm astc encoder "symbolic_to_physical"
    //uint bytes_of_one_endpoint = 2 * (color_endpoint_mode >> 2) + 2;

    uint blockmode = assemble_blockmode(weight_quantmethod);

    uint4 ep_ise = endpoint_ise(colorquant_index, ep0, ep1, endpoint_quantmethod);

    uint4 wt_ise = weight_ise(texels, weight_range - 1, ep0, ep1, weight_quantmethod);

    // assemble to astcblock
#if HAS_ALPHA
    uint color_endpoint_mode = CEM_LDR_RGBA_DIRECT;
#else
    uint color_endpoint_mode = CEM_LDR_RGB_DIRECT;
#endif
    return assemble_block(blockmode, color_endpoint_mode, 1, 0, ep_ise, wt_ise);
}

kernel void MainCS(
    texture2d<float, access::read> InTexture [[texture(0)]],
    device uint4* OutBuffer [[buffer(0)]],
    constant CSConstant& constants [[buffer(1)]],
    uint3 DTid [[thread_position_in_grid]])
{
    uint blockID = DTid.y * constants.InGroupNumX * THREAD_NUM_X + DTid.x;
    uint BlockNum = (constants.InTexelWidth + DIM - 1) / DIM;

    float4 texels[BLOCK_SIZE];
    for (int k = 0; k < BLOCK_SIZE; ++k)
    {        
        uint2 blockPos;
        blockPos.y = (uint)(blockID / BlockNum);
        blockPos.x = blockID - blockPos.y * BlockNum;
        
        uint y = k / DIM;
        uint x = k - y * DIM;
        uint2 pixelPos = blockPos * DIM + uint2(x, y);
        float4 texel = InTexture.read(pixelPos);
#if IS_NORMALMAP
        texel.b = 1.0f;
        texel.a = 1.0f;
#endif
        texels[k] = texel * 255.0f;
    }
    OutBuffer[blockID] = encode_block(texels);
} 