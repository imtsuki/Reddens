import Foundation
import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!

    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!

    weak var metalView: MTKView!

    init(metalView: MTKView) {
        super.init()

        // initialize the GPU and create the command queue
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device

        // set up the MTLLibrary and ensure that the vertex and fragment shader functions are present.
        let library = device.makeDefaultLibrary()
        Renderer.library = library

        let vertexFn = library?.makeFunction(name: "vertex_main")
        let fragmentFn = library?.makeFunction(name: "fragment_main")

        // create the pipeline state (expensive, one-time setup)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFn
        pipelineDescriptor.fragmentFunction = fragmentFn
        pipelineDescriptor.vertexDescriptor = defaultVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // set up the default mesh
        loadDefaultAsset()

        // set up the delegate
        metalView.clearColor = MTLClearColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        metalView.delegate = self
    }

    lazy var defaultVertexDescriptor: MTLVertexDescriptor = {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        return vertexDescriptor
    }()

    func loadAsset(url: URL) {
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)

        let meshDescriptor =
          MTKModelIOVertexDescriptorFromMetal(defaultVertexDescriptor)
        (meshDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition

        let asset = MDLAsset(
          url: url,
          vertexDescriptor: meshDescriptor,
          bufferAllocator: allocator)

        print("this asset has \(asset.count) object(s).")

        // TODO: render multiple objects
        let mdlMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh

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
    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        // drawing code goes here
        renderEncoder.setTriangleFillMode(.lines)

        renderEncoder.setRenderPipelineState(pipelineState)

        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

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
