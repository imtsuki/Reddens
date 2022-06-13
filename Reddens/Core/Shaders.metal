#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(const VertexIn vertex_in [[stage_in]], constant Uniforms &uniforms [[buffer(11)]]) {
    float4 translation = uniforms.modelMatrix * vertex_in.position;
    VertexOut vertex_out {
        .position = translation
    };
    return vertex_out;
}


fragment float4 fragment_main(constant float4 &color [[buffer(0)]]) {
    return color;
}
