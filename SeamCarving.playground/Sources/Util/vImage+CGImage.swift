import Accelerate.vImage

public extension CGImage {
    var planarBuffer: vImage_Buffer {
        let sourceFormat = vImage_CGImageFormat(cgImage: self)!
        
        let sourceBuffer = try! vImage_Buffer(cgImage: self)
        var destBuffer = try! vImage_Buffer(width: Int(sourceBuffer.width),
                                            height: Int(sourceBuffer.height),
                                            bitsPerPixel: vImage_CGImageFormat.planar8.bitsPerPixel)
        
        let converter = try? vImageConverter.make(sourceFormat: sourceFormat,
                                                  destinationFormat: .planar8)
        do {
            try converter?.convert(source: sourceBuffer,
                                   destination: &destBuffer)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        sourceBuffer.free()
        
        return destBuffer
    }
    
    var argbBuffer: vImage_Buffer {
        let sourceFormat = vImage_CGImageFormat(cgImage: self)!
        
        let sourceBuffer = try! vImage_Buffer(cgImage: self)
        var destBuffer = try! vImage_Buffer(width: Int(sourceBuffer.width),
                                            height: Int(sourceBuffer.height),
                                            bitsPerPixel: vImage_CGImageFormat.argb8.bitsPerPixel)
        
        let converter = try? vImageConverter.make(sourceFormat: sourceFormat,
                                                  destinationFormat: .argb8)
        do {
            try converter?.convert(source: sourceBuffer,
                                   destination: &destBuffer)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        sourceBuffer.free()
        
        return destBuffer
    }
}

public extension vImage_CGImageFormat {
    static let planar8 = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent
    )!
    
    static let planar64 = vImage_CGImageFormat(
        bitsPerComponent: 64,
        bitsPerPixel: 64,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent
    )!
    
    static let argb8 = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
        renderingIntent: .defaultIntent
    )!
}

