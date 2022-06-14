#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

typedef struct {
    uint32_t width;
    uint32_t height;
    uint32_t lightingMode;
} Params;

typedef enum {
    VertexBufferIndex = 0,
    UniformsBufferIndex = 11,
    ParamsBufferIndex = 12,
} BufferIndices;

#endif /* Common_h */
