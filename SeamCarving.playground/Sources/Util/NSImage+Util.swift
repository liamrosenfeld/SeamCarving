import AppKit
import AVFoundation

public extension NSImage {
    var cgImage: CGImage {
        self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    }
    
    var realSize: NSSize {
        let rep = representations[0]
        return NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }
    
    convenience init(ciImage: CIImage) {
        let rep = NSCIImageRep(ciImage: ciImage)
        self.init(size: rep.size)
        self.addRepresentation(rep)
    }
    
    func makeRep(at size: NSSize) -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(size.width),
                                   pixelsHigh: Int(size.height),
                                   bitsPerSample: 8,
                                   samplesPerPixel: 4,
                                   hasAlpha: true,
                                   isPlanar: false,
                                   colorSpaceName: .calibratedRGB,
                                   bytesPerRow: 0,
                                   bitsPerPixel: 0)
        return rep!
    }
    
    func constrained(to constraint: NSSize) -> NSImage {
        // don't resize if already small enough
        let isTooBig =
            self.realSize.width  > constraint.width ||
            self.realSize.height > constraint.height
        if !isTooBig {
            return self
        }
        
        // find constrained size
        let maxRect    = CGRect(origin: .zero, size: constraint)
        let scaledRect = AVMakeRect(aspectRatio: self.size, insideRect: maxRect)
        let scaledSize = scaledRect.size.rounded
        
        // Set Graphics State
        let rep = self.makeRep(at: scaledSize)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        
        // Place Image in Rep
        let destRect = NSRect(origin: CGPoint.zero, size: scaledSize)
        self.draw(in: destRect, from: NSRect.zero, operation: NSCompositingOperation.copy, fraction: 1.0)
        
        // Return rep as Image
        NSGraphicsContext.restoreGraphicsState()
        let newImage = NSImage(size: scaledSize)
        newImage.addRepresentation(rep)
        newImage.size = scaledSize
        
        return newImage
    }
}
