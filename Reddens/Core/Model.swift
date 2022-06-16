import Foundation
import MetalKit

class Model {
    var meshes: [MTKMesh] = []

    init(asset: MDLAsset) {
        let mtkMeshes = try! MTKMesh.newMeshes(asset: asset, device: Renderer.device).metalKitMeshes
        print("asset \(String(reflecting: asset.url?.lastPathComponent ?? "")) has \(mtkMeshes.count) mesh(es).")
        meshes = mtkMeshes
    }

    func render(
        encoder: MTLRenderCommandEncoder,
        uniforms vertex: Uniforms,
        params fragment: Params
    ) {
        var uniforms = vertex
        var params = fragment

        for mesh in meshes {
            encoder.setVertexBuffer(
                mesh.vertexBuffers[0].buffer,
                offset: 0,
                index: Int(VertexBufferIndex.rawValue)
            )

            encoder.setVertexBytes(
                &uniforms,
                length: MemoryLayout<Uniforms>.stride,
                index: Int(UniformsBufferIndex.rawValue)
            )

            encoder.setFragmentBytes(
                &params,
                length: MemoryLayout<Params>.stride,
                index: Int(ParamsBufferIndex.rawValue)
            )

            // draw the transformed object
            for submesh in mesh.submeshes {
                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer.buffer,
                    indexBufferOffset: submesh.indexBuffer.offset
                )
            }
        }
    }
}
