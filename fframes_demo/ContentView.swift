import SwiftUI
import AVKit

struct ContentView: View {
    @State private var videoURL: URL? = nil
    
    // Step 1: Define the function
    func renderVideo() {
        let fframes = Demo()
        let videoPath = fframes.renderVideo(slug: "The demo")
        videoURL = URL(fileURLWithPath: videoPath)
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Let's render fframes video!")
            
            Button(action: {
                renderVideo()
            }) {
                Text("Render video")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Step 3: Display the video
            if let videoURL = videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300) // Adjust the frame size as needed
                    .padding()
            }
        }
        .padding()
    }
}
