#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
    float4 position [[attribute(VertexAttributePosition)]];
    float3 normal [[attribute(VertexAttributeNormal)]];
    float2 uv [[attribute(VertexAttributeUV)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float2 uv;
};

vertex VertexOut vertex_main(
                             const VertexIn vertex_in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(UniformsBufferIndex)]]
) {
    float4 translation = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertex_in.position;
    VertexOut vertex_out {
        .position = translation,
        .normal = vertex_in.normal,
        .uv = vertex_in.uv,
    };
    return vertex_out;
}

fragment float4 fragment_main(
                              VertexOut in [[stage_in]],
                              constant Params &params [[buffer(ParamsBufferIndex)]],
                              texture2d<float> base_color_texture [[texture(BaseColorIndex)]]
) {
    constexpr sampler texture_sampler;
    if (params.lightingMode == 1) {
        float3 base_color = base_color_texture.sample(texture_sampler, in.uv).rgb;
        float4 sky = float4(base_color, 1.0);
        float4 earth = float4(base_color * 0.5, 1.0);
        float intensity = in.normal.y * 0.5 + 0.5;
        return mix(earth, sky, intensity);
    } else {
        return float4(in.normal, 1);
    }
}
