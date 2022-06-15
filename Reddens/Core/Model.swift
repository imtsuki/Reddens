import Foundation
import MetalKit

class Model {
    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!

    init(asset: MDLAsset) {
        print("asset \(String(describing: asset.url?.lastPathComponent)) has \(asset.count) object(s).")

        // TODO: render multiple objects
        let mdlMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh
        mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 1.0)

        do {
            mesh = try MTKMesh(mesh: mdlMesh, device: Renderer.device)
        } catch let error {
            print(error.localizedDescription)
        }

        // set up the MTLBuffer that contains the vertex data
        vertexBuffer = mesh.vertexBuffers[0].buffer
    }

    func render(
        encoder: MTLRenderCommandEncoder,
        uniforms vertex: Uniforms,
        params fragment: Params
    ) {
        var uniforms = vertex
        var params = fragment

        encoder.setVertexBuffer(
            vertexBuffer,
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
