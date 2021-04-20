import Foundation
import AppKit

public func carveImage(_ image: CGImage, width: Int) -> CGImage {
    var carvedImage = image
    
    let widthDiff = image.width - width
    for _ in 0..<widthDiff {
        let sobeled = sobel(carvedImage)
        let grayscale = sobeled.planarBuffer
        let (sums, dirs) = edginessSums(buffer: grayscale)
        grayscale.free()
        let seam = findSeam(edginessSums: sums, directions: dirs)
        var imageMatrix = carvedImage.argbBuffer.argb8ToMatrix()
        removeSeam(seam, from: &imageMatrix)
        carvedImage = CGImage.argbFromMatrix(imageMatrix)
    }
    
    // reassemble
    let newSize = NSSize(width: carvedImage.width, height: carvedImage.height)
    
    return NSImage(cgImage: carvedImage, size: newSize).cgImage
}

public func sharedCarveImage(_ image: CGImage, width: Int) -> CGImage {
    let widthDiff = image.width - width
    
    let sobeledImage = sobel(image)
    let grayscale = sobeledImage.planarBuffer
    
    var imageMatrix = image.argbBuffer.argb8ToMatrix()
    var sobelMatrix = grayscale.planarToMatrix()
    grayscale.free()
    
    for _ in 0..<widthDiff {
        let (sums, dirs) = edginessSums(intensities: sobelMatrix)
        let seam = findSeam(edginessSums: sums, directions: dirs)
        removeSeam(seam, from: &imageMatrix)
        removeSeam(seam, from: &sobelMatrix)
    }
    
    // reassemble
    let carvedImage = CGImage.argbFromMatrix(imageMatrix)
    let newSize = NSSize(width: width, height: image.height)
    
    return NSImage(cgImage: carvedImage, size: newSize).cgImage
}

public func balancedCarveImage(_ image: CGImage, width: Int, sobelPer: Int) -> CGImage {
    let widthDiff = image.width - width
    
    let sobeledImage = sobel(image)
    let grayscale = sobeledImage.planarBuffer
    
    var imageMatrix = image.argbBuffer.argb8ToMatrix()
    var sobelMatrix = grayscale.planarToMatrix()
    grayscale.free()
    
    for removalNum in 0..<widthDiff {
        if removalNum % sobelPer == 0 {
            let sobeledImage = sobel(CGImage.argbFromMatrix(imageMatrix))
            let grayscale = sobeledImage.planarBuffer
            sobelMatrix = grayscale.planarToMatrix()
        }
        
        let (sums, dirs) = edginessSums(intensities: sobelMatrix)
        let seam = findSeam(edginessSums: sums, directions: dirs)
        removeSeam(seam, from: &imageMatrix)
        removeSeam(seam, from: &sobelMatrix)
    }
    
    // reassemble
    let carvedImage = CGImage.argbFromMatrix(imageMatrix)
    let newSize = NSSize(width: width, height: image.height)
    
    return NSImage(cgImage: carvedImage, size: newSize).cgImage
}
