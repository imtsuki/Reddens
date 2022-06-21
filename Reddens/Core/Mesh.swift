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
        if let material = self.mdlSubmesh.material {
            self.texture.baseColor = Texture.extract(from: material, with: .baseColor)
        } else {
            self.texture.baseColor = Texture.solidColor()
        }
    }
}
