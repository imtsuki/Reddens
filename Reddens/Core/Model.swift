import Foundation
import MetalKit

class Model {
    var meshes: [MTKMesh] = []

    init(asset: MDLAsset) {
        let mdlMeshes = try! MTKMesh.newMeshes(asset: asset, device: Renderer.device).modelIOMeshes
        print("asset \(asset.url?.lastPathComponent ?? "") has \(mdlMeshes.count) mesh(es).")
        // TODO: do not generate normals if the model already contains normals data
        mdlMeshes.forEach({ $0.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.1) })
        let mtkMeshes = mdlMeshes.map({ try! MTKMesh(mesh: $0, device: Renderer.device) })
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
