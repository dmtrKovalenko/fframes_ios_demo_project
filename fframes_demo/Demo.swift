import Foundation

class Demo {
    func renderVideo(slug: String) -> String {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Create a new directory named "FFmpegOutput" in the documents directory
        let outputDirectoryPath = documentsDirectory.appendingPathComponent("fframes_output")
        
            // Create the directory if it doesn't exist
            try! fileManager.createDirectory(at: outputDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            
            // Clear the directory if it already exists
            let existingFiles = try! fileManager.contentsOfDirectory(at: outputDirectoryPath, includingPropertiesForKeys: nil, options: [])
            for file in existingFiles {
                try! fileManager.removeItem(at: file)
            }
            
            // Create the output file path
            let outputFilePath = outputDirectoryPath.appendingPathComponent("video.mp4").path
            
            // Call fframes_render with the new arguments
            fframes_render(slug, outputFilePath, outputDirectoryPath.path)
            
            return outputFilePath
    }
}
