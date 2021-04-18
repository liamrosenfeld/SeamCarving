import AppKit

struct ImageFile: Hashable {
    var name: String
    var url: URL
    
    init(url: URL) {
        self.name = url.deletingPathExtension().lastPathComponent
        self.url = url
    }
    
    func scaledArgbImage() -> NSImage? {
        // get image from file
        let image = NSImage(byReferencing: url)
        guard image.isValid else { return nil }
        
        // normalize the image format
        // keeps the convolution working smoothly
        let buffer = image.cgImage.argbBuffer
        let cgImage = try! buffer.createCGImage(format: .argb8)
        buffer.free()
        let normalized = NSImage(cgImage: cgImage, size: image.realSize)
        
        // resize constrain image to size
        let maxSize = NSSize(width: 300, height: 300)
        return normalized.constrained(to: maxSize)
    }
    
    static func getAll() -> [ImageFile] {
        guard let imageDir = Bundle.main
                .url(forResource: "markerfile", withExtension: "txt")?
                .resolvingSymlinksInPath()
                .deletingLastPathComponent()
                .appendingPathComponent("Images")
        else {
            fatalError("Shared Resources Directory Not Found")
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: imageDir, includingPropertiesForKeys: nil)
            let files = fileURLs.map { ImageFile(url: $0) }
            return files
        } catch {
            print("Error while enumerating files \(imageDir.path): \(error.localizedDescription)")
            return []
        }
    }
}
