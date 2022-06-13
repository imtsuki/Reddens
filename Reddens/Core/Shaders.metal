#include <metal_stdlib>
using namespace metal;


struct VertexIn {
    float4 position [[attribute(0)]];
};

vertex float4 vertex_main(const VertexIn vertex_in [[stage_in]]) {
    float4 position = vertex_in.position;
    return position;
}


fragment float4 fragment_main() {
    return float4(0, 1, 0, 1);
}
