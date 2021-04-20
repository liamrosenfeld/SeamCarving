import Foundation
import AppKit

public func carveImage(_ image: CGImage, width: Int) -> CGImage {
    var carvedImage = image
    
    let widthDiff = image.width - width
    for _ in 0..<widthDiff {
        // get sobeled image
        let sobeledImage  = sobel(carvedImage)
        let sobeledBuffer = sobeledImage.planarBuffer
        
        // get sums from sobel
        let (sums, dirs) = edginessSums(buffer: sobeledBuffer)
        sobeledBuffer.free()
        
        // find seam
        let seam = findSeam(edginessSums: sums, directions: dirs)
        
        // get matrix of image
        let imageBuffer = carvedImage.argbBuffer
        var imageMatrix = imageBuffer.argb8ToMatrix()
        imageBuffer.free()
        
        // apply seam
        removeSeam(seam, from: &imageMatrix)
        
        // turn matrix into image so Sobel filter can be reapplied
        carvedImage = CGImage.argbFromMatrix(imageMatrix)
    }
    
    // reassemble
    let newSize = NSSize(width: carvedImage.width, height: carvedImage.height)
    
    return NSImage(cgImage: carvedImage, size: newSize).cgImage
}

public func sharedCarveImage(_ image: CGImage, width: Int) -> CGImage {
    let widthDiff = image.width - width
    
    // get sobeled image
    let sobeledImage  = sobel(image)
    let sobeledBuffer = sobeledImage.planarBuffer
    
    // get matrix of both
    let imageBuffer = image.argbBuffer
    var imageMatrix = imageBuffer.argb8ToMatrix()
    imageBuffer.free()
    
    var sobelMatrix = sobeledBuffer.planarToMatrix()
    sobeledBuffer.free()
    
    for _ in 0..<widthDiff {
        // get sums and seam
        let (sums, dirs) = edginessSums(intensities: sobelMatrix)
        let seam = findSeam(edginessSums: sums, directions: dirs)
        
        // apply seam to both sobel and image
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
    
    // apply initial sobel
    let sobeledImage  = sobel(image)
    let sobeledBuffer = sobeledImage.planarBuffer
    
    // get matrixes of orig and sobel
    let imageBuffer = image.argbBuffer
    var imageMatrix = imageBuffer.argb8ToMatrix()
    imageBuffer.free()
    
    var sobelMatrix = sobeledBuffer.planarToMatrix()
    sobeledBuffer.free()
    
    for removalNum in 0..<widthDiff {
        // reapply and replace sobel matrix every sobelPer
        if removalNum % sobelPer == 0 {
            let sobeledImage = sobel(CGImage.argbFromMatrix(imageMatrix))
            let sobeledBuffer = sobeledImage.planarBuffer
            sobelMatrix = sobeledBuffer.planarToMatrix()
            sobeledBuffer.free()
        }
        
        // get sum and seam
        let (sums, dirs) = edginessSums(intensities: sobelMatrix)
        let seam = findSeam(edginessSums: sums, directions: dirs)
        
        // apply seam on image and sobel matrix
        removeSeam(seam, from: &imageMatrix)
        removeSeam(seam, from: &sobelMatrix)
    }
    
    // reassemble
    let carvedImage = CGImage.argbFromMatrix(imageMatrix)
    let newSize = NSSize(width: width, height: image.height)
    
    return NSImage(cgImage: carvedImage, size: newSize).cgImage
}
