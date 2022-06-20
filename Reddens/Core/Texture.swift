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
}
