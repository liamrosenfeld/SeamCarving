/*:
 # Finding Seams
 
 Seams will be what we call the path of pixels that we remove from the image to reduce its width.
 
 Our criteria for the seam is as follows:
 - The path that crosses the least edges
 - The path can lead to the three pixels under it (directly under and both diagonally adjacent)
 
 ## Possible Algoritms
 
 One attempt at finding this seem may be using a greedy algorithm. The lowest of the three candidates would be chosen for each row of the image. While that may be optimized, it would have issues consistency finding the best path. The seam can only move so fast horizontally because it can only move by one column per row, so taking a strictly greedy algorithm could easily get the seam stuck only having the option between pixels with a high edginess.
 
 The pitfall of now knowing if the path is the most optimal path possible can be removed by using an algorithm that checks for all possible paths through an image.
 It would then choose the path where the sum of all the edginess values is the least. While that would always give us the best possible path through an image, it is also extremely slow. The time complexity would on the order of 3^rows, which means it would no be practical to apply to any reasonably sized image.
 
 ## Optimizing Through Dynamic Programming
 
 Dynamic programming is a technique for optimizing algorithms by breaking them into subparts that are able to be shared.
 
 The fundamental fact that will allow us to optimize is that at each pixel, there is a path of least edginess to the bottom of the image, that path is will be the path of the rest of the seam if that pixel is in the seam.
 
 That allows us to assign each pixel the value of the total edginess the most optimal path to the bottom.
 
 That matrix of sums can be built from the bottom up, so all that would be necessary for finding the sum at each pixel get the minimum sum of the candidates below it and then add it to the value of itself.

 That greatly optimizes the algorithm by removing the redundant work, bringing the time complexity down to the much more reasonable 3 * rows * cols.
 
 # Implementation

 Below is a function to get the intensity sums from an accelerate buffer of the results of a Sobel filter. How each part functions is explained in the comments.
 */

import Accelerate.vImage

func _intensitySums(buffer: vImage_Buffer) -> (intensitySums: [[UInt32]], directions: [[Int8]]) {
    // make blank arrays of the appropriate size to store the output
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    
    // the values of path of least energy
    // max vertical resolution is 2^32/2^8 = 16,777,216
    // because that would be the amount of pixels it would take to overflow if every pixel of the edge detection is maxed out
    var intensitySums: [[UInt32]] = zeros(width: width, height: height)
    // the direction to the least point of least energy below (-1: left, 0: center, 1: right)
    var directions: [[Int8]] = zeros(width: width, height: height)
    
    // get a buffer pointer from the vImage pointer
    // allows it to be iterated over much easier
    let dataLength = height * buffer.rowBytes
    let dataPtr = buffer.data.bindMemory(to: UInt8.self, capacity: dataLength)
    let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: dataLength)
    
    // the bottom row is the same (no intensities below to add to it) so it can be copied over
    let lastRowStart = (height - 1) * buffer.rowBytes
    for col in 0..<width {
        intensitySums[height-1][col] = UInt32(dataBuffer[lastRowStart + col])
    }
    
    // adds from the bottom up, so it goes in reverse order
    // skips the very bottom row because it was already copied over
    for row in (0..<height-1).reversed() {
        // the offset in the buffer that the current row starts at
        let rowStart = row * buffer.rowBytes
        
        for col in 0..<width {
            // get the three values below the current pixel
            // if values are out of bounds the center value is added (because of the min and max)
            // it is faster to add multiple middles then allocating on the fly
            var valuesBelow: [(direction: Int8, intensitySum: UInt32)] = [
                (-1, intensitySums[row + 1][max(col - 1, 0)]),
                (0,  intensitySums[row + 1][col]),
                (1, intensitySums[row + 1][min(col + 1, width - 1)])
            ]
            
            // replace left index if it is equal to the center pixel
            // that either occurs because there is no left pixel or they just happen to be the same
            // in both cases, the preferred direction would be downwards
            //
            // because the min function uses <,
            // it is not necessary to change the index of the right pixel if they are equal
            if valuesBelow[0].intensitySum == valuesBelow[1].intensitySum {
                valuesBelow[0].direction = 0
            }
            
            // add together lowest intensity below and intensity of current pixel
            let smallestIntensityBelow = valuesBelow.min { $0.intensitySum < $1.intensitySum }!
            let intensityForThisPixel = UInt32(dataBuffer[rowStart + col]) // cast up to prevent overflow when adding
            intensitySums[row][col] = smallestIntensityBelow.intensitySum + intensityForThisPixel
            
            // add direction to the array
            directions[row][col] = smallestIntensityBelow.direction
        }
    }
    
    return (intensitySums, directions)
}

/*:
 The function returns two matrixes, one is the matrix of sums. The other is the direction to the sum of least value, which will speed up finding the seam because that will not need to be recomputed.
 
 Let's get both of those from our function and then visualize them as images.
 
 (This will call an identical function in a different file because the side view updating would make it unbearably slow)
 */

import AppKit

// get sobeled image
let image = NSImage(named: "pom.png")!.cgImage
let sobeled = sobel(image)
let buffer = sobeled.planarBuffer

// get sums and direction from sobeled buffer
let (sums, dirs) = intensitySums(buffer: buffer)
buffer.free()

// turn returned matrixes into images
let sumsImage = CGImage.scaledGrayscaleFromMatrix(sums)
let dirsColors = directionsToColorMatrix(dirs) // expresses left, center, and right as RGB respectively
let dirsImage = CGImage.argbFromMatrix(dirsColors)

//: Now we can see the results of the algorithm in the live view

sumsImage
dirsImage

/*:
 The triangular pattern that appears in the sums is significant because it marks out places that if the path ever touched, there would be no way to dodge the edge causing the triangle because, of the maximum rate the path can travel horizontally.
 
 # Seam Finding
 
 Now that we have the directions for every pixel in the image and the sum of the path of minimum edginess from each pixel in the top row, an array containing the col of each pixel to remove can be easily derived.
 
 The function to do so is
 */

func _findSeam(intensitySum: [[UInt32]], directions: [[Int8]]) -> [Int] {
    var seam: [Int] = Array(repeating: 0, count: intensitySum.count)
    
    // get the starting col
    // it will be the pixel with the minimum sum in the top row
    let start = intensitySum[0]
        .enumerated()
        .min { $0.element < $1.element }!
        .offset
    seam[0] = start
    
    // follow the directions to get the rest of the seam
    var col = start
    for row in 1..<directions.count {
        col += Int(directions[row][col])
        seam[row] = col
    }
    
    return seam
}

//: Now let's find the seam using the function we made

let seam = findSeam(intensitySum: sums, directions: dirs)

//: And then overlay it on the original image

var imageMatrix = image.argbBuffer.argb8ToMatrix()
let overlayedMatrix = overlaySeam(seam, on: imageMatrix, color: 0x00FF0000) // draw the seam in bid endian green
let overlayedImage = CGImage.argbFromMatrix(overlayedMatrix)

//: You can now see how the green line dodges important parts of the image

overlayedImage

//: Now we can remove that seam from the image

removeSeam(seam, from: &imageMatrix)
let carvedImage = CGImage.argbFromMatrix(imageMatrix)

//: If you look at the side bar, you can see that the width of the image is one pixel smaller
carvedImage

/*:
 While this proves that our algorithm is functional, we have not yet implemented it at the scale where it makes a noticeable difference on the image.
 
 That is what we will do [Next](@next)
 */
