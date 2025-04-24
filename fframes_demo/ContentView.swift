import SwiftUI
import AVKit

struct ContentView: View {
    @State private var videoURL: URL? = nil
    @State private var rustRenderer: RustVideoRenderer? = nil
    @State private var currentFrame: Int64 = 0
    @State private var isPlaying: Bool = false
    @State private var timer: Timer? = nil
    
    // Canvas dimensions - match these with your Rust renderer
    private let canvasWidth = 1920
    private let canvasHeight = 1080
    
    // Step 1: Define the function to render a video file
    func renderVideo() {
        let fframes = Demo()
        let videoPath = fframes.renderVideo(slug: "Video file")
        videoURL = URL(fileURLWithPath: videoPath)
    }
    
    // Initialize the Rust renderer for live canvas
    func initializeRenderer() {
        if rustRenderer == nil {
            rustRenderer = RustVideoRenderer(
                slug: "Canvas Preview"
            )
            currentFrame = 0
        }
    }
    
    // Control playback on the canvas
    func togglePlayback() {
        isPlaying.toggle()
        updateTimerBasedOnPlayState()
    }
    
    // Update timer based on play state
    func updateTimerBasedOnPlayState() {
        // Always invalidate existing timer first
        timer?.invalidate()
        timer = nil
        
        // Only create a new timer if we're playing
        if isPlaying {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
                currentFrame += 1
            }
        }
    }
    
    // Step forward one frame
    func stepForward() {
        currentFrame += 1
    }
    
    // Step backward one frame
    func stepBackward() {
        if currentFrame > 0 {
            currentFrame -= 1
        }
    }
    
    var body: some View {
        VStack {
            Text("fframes RT canvas ✌️")
                .font(.title)
                .padding()
            
            // Metal canvas for live rendering
            if let renderer = rustRenderer {
                MetalCanvasView(renderer: renderer, frameNumber: $currentFrame, isPlaying: $isPlaying)
                    .frame(height: 300)
                    .cornerRadius(8)
                    .padding()
                    .onChange(of: isPlaying) { newValue in
                        // This ensures we respond to isPlaying changes from child views
                        updateTimerBasedOnPlayState()
                    }
                
                // Playback controls
                HStack {
                    Button(action: stepBackward) {
                        Image(systemName: "backward.fill")
                            .padding()
                    }
                    
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .padding()
                    }
                    
                    Button(action: stepForward) {
                        Image(systemName: "forward.fill")
                            .padding()
                    }
                }
                
                Text("Frame: \(currentFrame)")
                    .padding()
            } else {
                Button(action: initializeRenderer) {
                    Text("Initialize Live Canvas")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            
            Divider()
                .padding()
            
            // Original video rendering section
            Button(action: renderVideo) {
                Text("Render Full Video")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Display the rendered video
            if let videoURL = videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .padding()
            }
        }
        .padding()
        .onDisappear {
            cleanup()
        }
    }
    
    // Clean up timer when view disappears
    private func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}
