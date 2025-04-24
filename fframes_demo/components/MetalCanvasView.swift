import SwiftUI
import MetalKit

struct MetalCanvasView: UIViewRepresentable {
    var renderer: RustVideoRenderer
    @Binding var frameNumber: Int64
    @Binding var isPlaying: Bool // Add this binding to control playback state
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = false
        mtkView.enableSetNeedsDisplay = true
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        // Set content mode equivalent (this is done in the draw method)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Render the frame whenever frameNumber changes
        if context.coordinator.lastRenderedFrame != frameNumber {
            context.coordinator.lastRenderedFrame = frameNumber
            let hasNexFrame = renderer.renderFrame(frameNumber)
            
            if !hasNexFrame {
                DispatchQueue.main.async {
                    isPlaying = false
                }
            }
            
            uiView.draw()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalCanvasView
        var lastRenderedFrame: Int64 = -1
        
        init(_ parent: MetalCanvasView) {
            self.parent = parent
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Size changed, we'll handle scaling in the draw method
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let commandBuffer = view.device?.makeCommandQueue()?.makeCommandBuffer() else {
                return
            }
            
            // Get the source texture
            let sourceTexture = parent.renderer.getTexture()
            
            // Clear the drawable
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.endEncoding()
            
            // Get drawable dimensions
            let drawableWidth = Int(drawable.texture.width)
            let drawableHeight = Int(drawable.texture.height)
            
            // Instead of trying to scale, just extract a center portion of the source texture
            // that will fit inside the drawable
            if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                // Calculate a region from the center of the source texture
                let sourceWidth = Int(sourceTexture.width)
                let sourceHeight = Int(sourceTexture.height)
                
                let copyWidth = min(sourceWidth, drawableWidth)
                let copyHeight = min(sourceHeight, drawableHeight)
                
                let sourceX = (sourceWidth - copyWidth) / 2
                let sourceY = (sourceHeight - copyHeight) / 2
                
                blitEncoder.copy(
                    from: sourceTexture,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: MTLOrigin(x: sourceX, y: sourceY, z: 0),
                    sourceSize: MTLSize(width: copyWidth, height: copyHeight, depth: 1),
                    to: drawable.texture,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
                )
                blitEncoder.endEncoding()
            }
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
