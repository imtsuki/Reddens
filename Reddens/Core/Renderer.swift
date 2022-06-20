import Foundation
import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    static var textureLoader: MTKTextureLoader!

    static var defaultMDLVertexDescriptor: MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        vertexDescriptor.attributes[VertexAttributePosition.index] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: offset,
            bufferIndex: VertexBufferIndex.index
        )
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[VertexAttributeNormal.index] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: offset,
            bufferIndex: VertexBufferIndex.index
        )
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[VertexBufferIndex.index] = MDLVertexBufferLayout(stride: offset)

        // store UV in a separate buffer

        offset = 0

        vertexDescriptor.attributes[VertexAttributeUV.index] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: offset,
            bufferIndex: UVBufferIndex.index
        )
        offset += MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[UVBufferIndex.index] = MDLVertexBufferLayout(stride: offset)

        return vertexDescriptor
    }

    static var defaultMTLVertexDescriptor: MTLVertexDescriptor {
        return MTKMetalVertexDescriptorFromModelIO(defaultMDLVertexDescriptor)!
    }

    static var depthStencilState: MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(
            descriptor: descriptor)
    }

    var pipelineState: MTLRenderPipelineState!
    var model: Model?

    var uniforms = Uniforms()
    var params = Params()

    var inspectorPreferences: InspectorModel.Preferences = InspectorModel.Preferences()

    init(mtkView: MTKView) {
        super.init()

        // initialize the GPU and create the command queue
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        mtkView.device = device

        // set up the MTLLibrary and ensure that the vertex and fragment shader functions are present.
        let library = device.makeDefaultLibrary()
        Renderer.library = library

        let vertexFn = library?.makeFunction(name: "vertex_main")
        let fragmentFn = library?.makeFunction(name: "fragment_main")

        Renderer.textureLoader = MTKTextureLoader(device: device)

        // create the pipeline state (expensive, one-time setup)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFn
        pipelineDescriptor.fragmentFunction = fragmentFn
        pipelineDescriptor.vertexDescriptor = Renderer.defaultMTLVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // load the default model
        loadDefaultAsset()

        // set up the delegate
        mtkView.clearColor = MTLClearColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.delegate = self
    }

    func loadAsset(url: URL) {
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)

        let vertexDescriptor = Renderer.defaultMDLVertexDescriptor

        let asset = MDLAsset(
          url: url,
          vertexDescriptor: vertexDescriptor,
          bufferAllocator: allocator)

        model = Model(asset: asset)
    }

    func loadDefaultAsset() {
        guard let assetURL = Bundle.main.url(forResource: "Donut", withExtension: "obj") else {
            fatalError()
        }
        loadAsset(url: assetURL)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        params.width = UInt32(size.width)
        params.height = UInt32(size.height)
        let aspectRatio = size.width / size.height

        let projectionMatrix = float4x4(
            projectionFov: 45 / 180 * Float.pi, near: 0.1,
            far: 100,
            aspectRatio: Float(aspectRatio))

        uniforms.projectionMatrix = projectionMatrix
    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        switch inspectorPreferences.lightingMode {
        case .normal:
            params.lightingMode = 0
        case .hemispheric:
            params.lightingMode = 1
        }

        // scaling -> rotation -> translation
        let translationMatrix = float4x4(translation: [inspectorPreferences.translationX, inspectorPreferences.translationY, 2])
        let scaling = powf(10, inspectorPreferences.modelScaling)
        let rotationMatrix = float4x4(rotation: [inspectorPreferences.rotationX, inspectorPreferences.rotationY, inspectorPreferences.rotationZ])
        let scalingMatrix = float4x4(scaling: [scaling, scaling, scaling])
        uniforms.modelMatrix = translationMatrix * rotationMatrix * scalingMatrix

        uniforms.viewMatrix = float4x4(translation: [0, 0, 0]).inverse

        // MARK: Start of drawing code
        renderEncoder.setDepthStencilState(Renderer.depthStencilState)

        renderEncoder.setTriangleFillMode(inspectorPreferences.triangleFillMode)

        renderEncoder.setRenderPipelineState(pipelineState)

        model?.render(encoder: renderEncoder, uniforms: uniforms, params: params)

        // MARK: End of drawing code
        renderEncoder.endEncoding()

        guard let drawable = view.currentDrawable else {
            return
        }
        // present the view’s drawable texture to the GPU
        commandBuffer.present(drawable)
        // send the encoded commands to the GPU for execution
        commandBuffer.commit()
    }
}
