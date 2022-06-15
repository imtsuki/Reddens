import Foundation
import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!

    static var defaultMDLVertexDescriptor: MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        vertexDescriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: offset,
            bufferIndex: Int(VertexBufferIndex.rawValue)
        )
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: offset,
            bufferIndex: Int(VertexBufferIndex.rawValue)
        )
        offset += MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)

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

    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!

    var uniforms = Uniforms()
    var params = Params()

    var timer: Float = 0

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

        // set up the default mesh
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

        print("this asset has \(asset.count) object(s).")

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

        // drawing code goes here
        switch inspectorPreferences.lightingMode {
        case .normal:
            params.lightingMode = 0
        case .hemispheric:
            params.lightingMode = 1
        }

        renderEncoder.setDepthStencilState(Renderer.depthStencilState)

        renderEncoder.setTriangleFillMode(inspectorPreferences.triangleFillMode)

        renderEncoder.setRenderPipelineState(pipelineState)

        renderEncoder.setVertexBuffer(
            vertexBuffer,
            offset: 0,
            index: Int(VertexBufferIndex.rawValue)
        )

        renderEncoder.setFragmentBytes(
            &params,
            length: MemoryLayout<Params>.stride,
            index: Int(ParamsBufferIndex.rawValue)
        )

        timer += 0.005

        uniforms.viewMatrix = float4x4(translation: [0, 0, 0]).inverse

        let translationMatrix = float4x4(translation: [0, 0, 2])
        let rotationMatrix = float4x4(rotationX: sin(timer) / 2 - 0.5)
        let scalingMatrix = float4x4(scaling: [inspectorPreferences.modelScaling, inspectorPreferences.modelScaling, inspectorPreferences.modelScaling])
        // scaling first, rotation next, translation last
        uniforms.modelMatrix = translationMatrix * rotationMatrix * scalingMatrix

        // draw the transformed object
        renderEncoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: Int(UniformsBufferIndex.rawValue)
        )

        for submesh in mesh.submeshes {
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: submesh.indexCount,
                indexType: submesh.indexType,
                indexBuffer: submesh.indexBuffer.buffer,
                indexBufferOffset: submesh.indexBuffer.offset
            )
        }
        // deawing code ends here

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
