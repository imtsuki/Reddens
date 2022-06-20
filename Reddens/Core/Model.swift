import MetalKit

class Model {
    var meshes: [Mesh] = []

    init(asset: MDLAsset) {
        asset.loadTextures()
        let (mdlMeshes, mtkMeshes) = try! MTKMesh.newMeshes(asset: asset, device: Renderer.device)
        for (mdlMesh, mtkMesh) in zip(mdlMeshes, mtkMeshes) {
            meshes.append(Mesh(mdlMesh: mdlMesh, mtkMesh: mtkMesh))
        }
        print("asset \(String(reflecting: asset.url?.lastPathComponent ?? "")) has \(meshes.count) mesh(es).")
    }

    func render(
        encoder: MTLRenderCommandEncoder,
        uniforms vertex: Uniforms,
        params fragment: Params
    ) {
        var uniforms = vertex
        var params = fragment

        for mesh in meshes {
            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                encoder.setVertexBuffer(
                    vertexBuffer.buffer,
                    offset: 0,
                    index: index
                )
            }

            encoder.setVertexBytes(
                &uniforms,
                length: MemoryLayout<Uniforms>.stride,
                index: UniformsBufferIndex.index
            )

            encoder.setFragmentBytes(
                &params,
                length: MemoryLayout<Params>.stride,
                index: ParamsBufferIndex.index
            )

            // draw the transformed object
            for submesh in mesh.submeshes {
                encoder.setFragmentTexture(
                    submesh.texture.baseColor,
                    index: BaseColorIndex.index
                )

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
