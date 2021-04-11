import AppKit
import Metal

public extension MTLTexture {
    /// Utility function for building a descriptor that matches this texture
    func matchingDescriptor() -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = self.textureType
        // NOTE: We should be more careful to select a renderable pixel format here,
        // especially if operating on a compressed texture.
        descriptor.pixelFormat = self.pixelFormat
        descriptor.width = self.width
        descriptor.height = self.height
        descriptor.depth = self.depth
        descriptor.mipmapLevelCount = self.mipmapLevelCount
        descriptor.arrayLength = self.arrayLength
        // NOTE: We don't set resourceOptions here, since we explicitly set cache and storage modes below.
        descriptor.cpuCacheMode = self.cpuCacheMode
        descriptor.storageMode = self.storageMode
        descriptor.usage = self.usage
        return descriptor
    }
}

public func zeros<T: Numeric>(width: Int, height: Int) -> [[T]] {
    return Array(repeating: Array(repeating: T(exactly: 0)!, count: width), count: height)
}

public extension CGSize {
    var rounded: CGSize {
        return CGSize(width: self.width.rounded(), height: self.height.rounded())
    }
}

public extension CIImage {
    var cgImage: CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(self, from: self.extent)
    }
}
