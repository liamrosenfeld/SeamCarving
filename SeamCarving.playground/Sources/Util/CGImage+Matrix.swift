import Foundation

extension CGImage {
    // CGContext init parameters from
    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB
    
    static func argbFromMatrix(_ matrix: [[UInt32]]) -> CGImage {
        // flattens matrix in row-major order
        var pixelValues = matrix.flatMap { $0 }
        
        let numComponents = 4
        let width = matrix[0].count
        let height = matrix.count
        
        let cgImg = pixelValues.withUnsafeMutableBytes { (ptr) -> CGImage in
            let ctx = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * numComponents,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue
                //            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue
            )!
            return ctx.makeImage()!
        }
        return cgImg
    }
    
    static func scaledGrayscaleFromMatrix(_ matrix: [[UInt32]]) -> CGImage {
        // flattens matrix in row-major order
        let flattened = matrix.flatMap { $0 }
        
        // scales the values so the difference between high and low intensity is more apparent
        // converts to uint8 so it can easily be displayed as an image
        let max = flattened.max()!
        var pixelValues: [UInt8] = flattened.map { uint in
            UInt8((uint * 255) / max)
        }
        
        let width = matrix[0].count
        let height = matrix.count
        
        let cgImg = pixelValues.withUnsafeMutableBytes { (ptr) -> CGImage in
            let ctx = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            )!
            return ctx.makeImage()!
        }
        return cgImg
    }
    
    static func grayscaleFromMatrix(_ matrix: [[UInt8]]) -> CGImage {
        // flattens matrix in row-major order
        var pixelValues = matrix.flatMap { $0 }
        
        let width = matrix[0].count
        let height = matrix.count
        
        let cgImg = pixelValues.withUnsafeMutableBytes { (ptr) -> CGImage in
            let ctx = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            )!
            return ctx.makeImage()!
        }
        return cgImg
    }
}
