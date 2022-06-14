#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
    float4 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
};

vertex VertexOut vertex_main(
                             const VertexIn vertex_in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(UniformsBufferIndex)]]
) {
    float4 translation = uniforms.modelMatrix * vertex_in.position;
    VertexOut vertex_out {
        .position = translation,
        .normal = vertex_in.normal
    };
    return vertex_out;
}


fragment float4 fragment_main(
                              VertexOut vertex_in [[stage_in]],
                              constant Params &params [[buffer(ParamsBufferIndex)]]
) {
    if (params.lightingMode == 1) {
        float4 sky = float4(0.34, 0.9, 1.0, 1.0);
        float4 earth = float4(0.29, 0.58, 0.2, 1.0);
        float intensity = vertex_in.normal.y * 0.5 + 0.5;
        return mix(earth, sky, intensity);
    } else {
        return float4(vertex_in.normal, 1);
    }
}
