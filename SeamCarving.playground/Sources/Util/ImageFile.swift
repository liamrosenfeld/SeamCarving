import AppKit

public struct ImageFile: Hashable {
    public var name: String
    var url: URL
    
    public init(url: URL) {
        self.name = url.deletingPathExtension().lastPathComponent
        self.url = url
    }
    
    public func scaledArgbImage() -> NSImage? {
        // get image from file
        // this method is needed because NSImage(named: ) is broken in playgrounds 12.4
        let image = NSImage(byReferencing: url)
        guard image.isValid else { return nil }
        
        // normalize the image format
        // keeps the convolution working smoothly
        let buffer = image.cgImage.argbBuffer
        let cgImage = try! buffer.createCGImage(format: .argb8)
        buffer.free()
        let normalized = NSImage(cgImage: cgImage, size: image.realSize)
        
        // resize constrain image to size
        let maxSize = NSSize(width: 350, height: 350)
        return normalized.constrained(to: maxSize)
    }
    
    private static var imageDir: URL = Bundle.main
        .url(forResource: "markerfile", withExtension: "txt")!
        .resolvingSymlinksInPath()
        .deletingLastPathComponent()
        .appendingPathComponent("Images")
    
    public static func getAll() -> [ImageFile] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: imageDir, includingPropertiesForKeys: nil)
            let files = fileURLs.map { ImageFile(url: $0) }
            return files
        } catch {
            print("Error while enumerating files \(imageDir.path): \(error.localizedDescription)")
            return []
        }
    }
    
    public static func get(named name: String) -> Self {
        let url = imageDir.appendingPathComponent(name)
        return ImageFile(url: url)
    }
}
