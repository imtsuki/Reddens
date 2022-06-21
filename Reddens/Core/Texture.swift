import MetalKit

class Texture {
    var baseColor: MTLTexture?

    static func solidColor(color input: SIMD3<Float> = [1, 0, 0]) -> MTLTexture? {
        let color = simd_float4(input, 1);
        let region = MTLRegionMake2D(0, 0, 1, 1)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: region.size.width,
            height: region.size.height,
            mipmapped: false
        )
        textureDescriptor.storageMode = .shared
        textureDescriptor.usage = .shaderRead
        let texture = Renderer.device.makeTexture(descriptor: textureDescriptor)
        withUnsafePointer(to: color) { ptr in
            texture?.replace(region: region, mipmapLevel: 0, withBytes: ptr, bytesPerRow: 32)
        }
        return texture
    }

    static func extract(from material: MDLMaterial, with semantic: MDLMaterialSemantic) -> MTLTexture? {
        if let property = material.property(with: semantic) {
            switch property.type {
            case .texture:
                let mdlTexture = property.textureSamplerValue?.texture
                let textureLoader = Renderer.textureLoader
                let options: [MTKTextureLoader.Option: Any] = [
                    .SRGB: false,
                    .origin: MTKTextureLoader.Origin.bottomLeft // Flip the image if needed
                ]
                return try? textureLoader?.newTexture(texture: mdlTexture!, options: options)
            case .float3:
                return Texture.solidColor(color: property.float3Value)
            case .string, .URL, .color, .float, .float2, .float4, .matrix44, .buffer:
                print("Unhandled material property type \(String(describing: property.type))")
                return Texture.solidColor()
            case .none:
                print("Material property not initialized")
                return Texture.solidColor()
            @unknown default:
                return Texture.solidColor()
            }
        } else {
            print("Material property not found")
            return Texture.solidColor()
        }
    }
}
