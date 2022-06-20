import Foundation
import MetalKit

struct Mesh {
    let mdlMesh: MDLMesh
    let mtkMesh: MTKMesh
    var submeshes: [Submesh] = []

    var vertexBuffers: [MTKMeshBuffer] {
        return mtkMesh.vertexBuffers
    }

    init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
        self.mdlMesh = mdlMesh
        self.mtkMesh = mtkMesh
        for (mdlSubmesh, mtkSubmesh) in zip(mdlMesh.submeshes!, mtkMesh.submeshes) {
            submeshes.append(Submesh(mdlSubmesh: mdlSubmesh as! MDLSubmesh, mtkSubmesh: mtkSubmesh))
        }
    }
}

struct Submesh {
    let mdlSubmesh: MDLSubmesh
    let mtkSubmesh: MTKSubmesh
    let baseColor: SIMD3<Float>

    var indexCount: Int {
        return mtkSubmesh.indexCount
    }

    var indexType: MTLIndexType {
        return mtkSubmesh.indexType
    }

    var indexBuffer: MTKMeshBuffer {
        return mtkSubmesh.indexBuffer
    }

    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
        self.mdlSubmesh = mdlSubmesh
        self.mtkSubmesh = mtkSubmesh
        if let baseColorProperty = mdlSubmesh.material?.property(with: .baseColor),
           baseColorProperty.type == .float3 {
            baseColor = baseColorProperty.float3Value
        } else {
            baseColor = [1, 0, 0]
        }
    }
}

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
                var baseColor = submesh.baseColor;
                encoder.setFragmentBytes(
                    &baseColor,
                    length: MemoryLayout<SIMD3<Float>>.stride,
                    index: Int(BaseColorIndex.rawValue)
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
