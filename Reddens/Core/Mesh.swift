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
    let texture: Texture

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
        self.texture = Texture()
        if let baseColorProperty = mdlSubmesh.material?.property(with: .baseColor) {
            if baseColorProperty.type == .texture {
                let mdlTexture = baseColorProperty.textureSamplerValue?.texture
                let textureLoader = Renderer.textureLoader
                let options: [MTKTextureLoader.Option: Any] = [
                    .SRGB: false,
                    .origin: MTKTextureLoader.Origin.bottomLeft // Flip the image if needed
                ]
                self.texture.baseColor = try? textureLoader?.newTexture(texture: mdlTexture!, options: options)
            } else if baseColorProperty.type == .float3 {
                self.texture.baseColor = Texture.solidColor(color: baseColorProperty.float3Value)
            } else {
                print("Unhandled property type \(String(describing: baseColorProperty.type))")
                self.texture.baseColor = Texture.solidColor()
            }
        } else {
            self.texture.baseColor = Texture.solidColor()
        }
    }
}
