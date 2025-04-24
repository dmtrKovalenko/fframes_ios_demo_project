import Metal
import MetalKit
import Foundation

class RustVideoRenderer {
    // MARK: - Properties
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var texture: MTLTexture
    private let width: Int = 1920  // Fixed Full HD width
    private let height: Int = 1080 // Fixed Full HD height
    
    // Rust pointers/handles
    private var metalContextPtr: UnsafeMutableRawPointer?
    private var videoInstancePtr: UnsafeMutableRawPointer?
    private var videoContextPtr: UnsafeMutableRawPointer?
    
    private var currentFrame: Int64 = 0
    
    // MARK: - Initialization
    
    init(slug: String) {
        // Create Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        
        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create command queue")
        }
        self.commandQueue = commandQueue
        
        // Create a Metal texture at Full HD resolution
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .shared
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Could not create texture")
        }
        self.texture = texture
        
        // Initialize the Rust components
        setupRustComponents(slug: slug)
    }
    
    private func setupRustComponents(slug: String) {
        // 1. Create video instance
        slug.withCString { slugPtr in
            videoInstancePtr = create_video_instance(slugPtr)
        }
        
        guard let videoInstancePtr = videoInstancePtr else {
            fatalError("Failed to create video instance")
        }
        
        // 2. Create video context
        videoContextPtr = create_fframes_video_ctx(videoInstancePtr)
        
        guard let videoContextPtr = videoContextPtr else {
            fatalError("Failed to create video context")
        }
        
        // 3. Create metal context with our Full HD texture
        let devicePtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(device).toOpaque())
        let commandQueuePtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(commandQueue).toOpaque())
        let texturePtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(texture).toOpaque())
        
        metalContextPtr = create_metal_context(
            devicePtr,
            commandQueuePtr,
            texturePtr,
            Int64(width),
            Int64(height)
        )
        
        guard let metalContextPtr = metalContextPtr else {
            fatalError("Failed to create metal context")
        }
    }
    
    // MARK: - Public Methods
    
    /// Renders a specific frame of the video
    /// Returns: Boolean indicating if rendering was successful
    func renderFrame(_ frameNumber: Int64) -> Bool {
        guard let metalContextPtr = metalContextPtr,
              let videoContextPtr = videoContextPtr,
              let videoInstancePtr = videoInstancePtr else {
            print("Cannot render: One or more contexts are nil")
            return false
        }
        
        let hasNextFrame = render_frame(
            metalContextPtr,
            videoContextPtr,
            videoInstancePtr,
            frameNumber
        )
        
        currentFrame = frameNumber
        return hasNextFrame
    }
    
    /// Renders the next frame
    /// Returns: Boolean indicating if rendering was successful
    func renderNextFrame() -> Bool {
        return renderFrame(currentFrame + 1)
    }
    
    /// Gets the Metal texture containing the rendered frame
    func getTexture() -> MTLTexture {
        return texture
    }
    
    /// Returns the dimensions of the rendered texture
    func getDimensions() -> (width: Int, height: Int) {
        return (width, height)
    }
    
    /// Renders the complete video to a file
    static func renderFullVideo(slug: String, outputPath: String, tmpDirectory: String) {
        slug.withCString { slugPtr in
            outputPath.withCString { outputPtr in
                tmpDirectory.withCString { tmpDirPtr in
                    fframes_render(slugPtr, outputPtr, tmpDirPtr)
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Free Rust resources
        // Note: If your Rust code has functions to free these resources, call them here
    }
}
