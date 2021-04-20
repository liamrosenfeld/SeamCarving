import Foundation

public class IntermediateGenerator {
    var image: CGImage
    
    init(for image: CGImage) {
        self.image = image
    }
    
    func sobeled() -> CGImage {
        return sobel(image)
    }
    
    func sums() -> CGImage {
        let sobeled = sobel(image)
        let buffer = sobeled.planarBuffer
        let (sums, _) = edginessSums(buffer: buffer)
        buffer.free()
        return CGImage.scaledGrayscaleFromMatrix(sums)
    }
    
    func directions() -> CGImage {
        let sobeled = sobel(image)
        let buffer = sobeled.planarBuffer
        let (_, dirs) = edginessSums(buffer: buffer)
        buffer.free()
        let matrix = directionsToColorMatrix(dirs)
        return CGImage.argbFromMatrix(matrix)
    }
    
    func seamOnSum() -> CGImage {
        let sobeled = sobel(image)
        let buffer = sobeled.planarBuffer
        let (sums, dirs) = edginessSums(buffer: buffer)
        buffer.free()
        let seam = findSeam(edginessSums: sums, directions: dirs)
        let overlayed = overlaySeam(seam, on: sums, color: 10000)
        return CGImage.scaledGrayscaleFromMatrix(overlayed)
    }
    
    func seamOnSobel() -> CGImage {
        let sobeled = sobel(image)
        let buffer = sobeled.planarBuffer
        let (sums, dirs) = edginessSums(buffer: buffer)
        buffer.free()
        let seam = findSeam(edginessSums: sums, directions: dirs)
        let overlay = overlaySeam(seam, on: buffer.planarToMatrix(), color: 255)
        return CGImage.grayscaleFromMatrix(overlay)
    }
    
    func seamOnOrig() -> CGImage {
        let sobeled = sobel(image)
        let buffer = sobeled.planarBuffer
        let (sums, dirs) = edginessSums(buffer: buffer)
        buffer.free()
        let seam = findSeam(edginessSums: sums, directions: dirs)
        let imageBuffer = image.argbBuffer
        let imageMatrix = imageBuffer.argb8ToMatrix()
        imageBuffer.free()
        let overlay = overlaySeam(seam, on: imageMatrix, color: 0x00FF0000)
        return CGImage.argbFromMatrix(overlay)
    }
}
