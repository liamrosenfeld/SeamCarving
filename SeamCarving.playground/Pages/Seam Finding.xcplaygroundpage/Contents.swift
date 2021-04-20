/*:
 # Finding Seams
 
 Seams will be what we call the path of pixels that we remove from the image to reduce its width.
 
 Our criteria for the seam is as follows:
 - The path that crosses the least edges (as determined by the Sobel filter)
 - The path can lead to the three pixels under the current pixel (directly under and both diagonally adjacent)
 
 Those three candidates are shown on this diagram:
 
 ![Candidate Diagram](/CandidateDiagram.jpg)
 
 ## Possible Algoritms
 
 One attempt at finding the seam may be using a greedy algorithm. A greedy algorithm is one that always picks the immediately most optimal option. In this case, it would always pick the lowest of the three three candidates available for each row of the image.
 
 While that may be optimized for performance, it has issues consistently finding the best path.
 
 The seam has a maximum horizontal speed of one column per row, so taking a strictly greedy algorithm could easily get the seam stuck only having candidates with high edginess (value of pixel from the Sobel Filter output) of the later in the image.
 
 The pitfall of not knowing if the path is the most optimal path possible can be removed by using an algorithm that checks for all possible paths through an image.
 
 It would then choose the path where the sum of all the edginess values is the least. While that would always give us the best possible path through an image, it is also extremely slow.
 
 The time complexity of that method would be on the order of `cols * 3^rows`, so it would not be of practical use on any reasonably sized image.
 
 ## Optimizing Through Dynamic Programming
 
 Dynamic programming is a technique for optimizing algorithms by breaking them into subparts that are able to be shared by other subparts. That can greatly reduce the need for redundant work.
 
 The fundamental fact that will allow us to optimize is that at each pixel, there is a path of minimum total edginess to the bottom of the image. Since that will always be the optimal path from that pixel, any seam that includes that pixel will follow that path for the rest of the image.
 
 That allows us to assign each pixel a value of the total edginess of the most optimal path to the bottom. Using that value for calculating the value of pixels above greatly decreases the amount of redundant work needed—a major dynamic programming win.
 
 To find the value for each pixel, the matrix of sums can be built from the bottom up. Since the total sum at each candidate would be known, all that would be necessary for finding the sum at each pixel is to add the minimum sum of the candidates and the value of itself.

 That greatly optimizes the algorithm by removing the redundant work, bringing the time complexity down to the much more reasonable `3 * rows * cols`.
 
 # Implementation
 
 We first need a min function that is able to find the minimum value and the index of that value. While an enumerated array would make sense for finding the minimum amount of a larger collection of values, a flattened version is more performance friendly at this scale.
 
 This function also differs from most min finding functions because it prefers the middle value over the sides if they are equal.
 
 This is preferable because they are equal when there is no left or right pixel (min and max are used to prevent overflows inline in our summing function) along with general preference for the seam to travel straight down if the options happen to be equivalent (leads to a generally less noticeable removal).
 
 This min function with our specific criteria can be implemented as below:
 */

func minWithIndex(_ val0: UInt32, _ val1: UInt32, _ val2: UInt32) -> (val: UInt32, index: Int8) {
    // prefer center index
    var index: Int8 = 1
    var min = val1
    
    // check left
    if val0 < min {
        index = 0
        min = val0
    }
    
    // check right
    if val2 < min {
        index = 2
        min = val2
    }
    
    return (min, index)
}

/*:
 Now we can use that function inside of our edginess summing function.
 
 Our function will take the result of our Sobel filter as an 8-bit planar accelerate buffer.
 
 It will return the sum and the direction (to the candidate chosen) at each pixel as two separate matrixes.
 They will both be needed to calculate our seam.
 
 How each part of the function works is explained in the inline comments.
 */

import Accelerate.vImage

func _edginessSums(buffer: vImage_Buffer) -> (edginessSums: [[UInt32]], directions: [[Int8]]) {
    // make blank arrays of the appropriate size to store the output
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    
    // the values of path of least energy
    // max vertical resolution is 2^32/2^8 = 16,777,216
    // because that would be the amount of pixels it would take to overflow if every pixel of the edge detection is maxed out
    var edginessSums: [[UInt32]] = zeros(width: width, height: height)
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
        edginessSums[height-1][col] = UInt32(dataBuffer[lastRowStart + col])
    }
    
    // adds from the bottom up, so it goes in reverse order
    // skips the very bottom row because it was already copied over
    for row in (0..<height-1).reversed() {
        // the offset in the buffer that the current row starts at
        let rowStart = row * buffer.rowBytes
        
        for col in 0..<width {
            // get min of the the three values below the current pixel
            // if values are out of bounds the center value is used (that is what the min and maxes are doing)
            // our custom min function ignores them if they have the same value as the center
            let (minBelow, minIndex) = minWithIndex(
                edginessSums[row + 1][max(col - 1, 0)],
                edginessSums[row + 1][col],
                edginessSums[row + 1][min(col + 1, width - 1)]
            )
            
            // add together lowest edginess below and edginess of current pixel
            let edginessForThisPixel = UInt32(dataBuffer[rowStart + col]) // cast up to prevent overflow when adding
            edginessSums[row][col] = minBelow + edginessForThisPixel
            
            // add direction to the array
            directions[row][col] = minIndex - 1
        }
    }
    
    return (edginessSums, directions)
}

/*:
 Let's get the sums and directions and then visualize them as images.
 
 (This will call an identical function in a different file because the side view updating would make it unbearably slow.)
 */

import AppKit

// get sobeled image
let image = ImageFile.get(named: "pom.png").scaledArgbImage()!.cgImage
let sobeled = sobel(image)
let buffer = sobeled.planarBuffer

// get sums and direction from sobeled buffer
let (sums, dirs) = edginessSums(buffer: buffer)
buffer.free()

// turn returned matrixes into images
let sumsImage = CGImage.scaledGrayscaleFromMatrix(sums)
let dirsColors = directionsToColorMatrix(dirs) // expresses left, center, and right as RGB respectively
let dirsImage = CGImage.argbFromMatrix(dirsColors)

//: Now we can see the results of the algorithm in the in the results view after running this page:

sumsImage
dirsImage

/*:
 The triangular pattern that appears above edges in the sums is significant because it marks out places, that if the path ever touched, there would be no way to dodge the edge. That reflects the maximum rate the path can travel horizontally.
 
 # Seam Finding
 
 Now that we have the directions for every pixel in the image and the sum of the path of minimum edginess from each pixel in the top row, an array containing the column of each pixel to remove can be easily derived.
 
 The function to do so is
 */

func _findSeam(edginessSums: [[UInt32]], directions: [[Int8]]) -> [Int] {
    var seam: [Int] = Array(repeating: 0, count: edginessSums.count)
    
    // get the starting col
    // it will be the pixel with the minimum sum in the top row
    let start = edginessSums[0]
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

//: Let's find the seam using the function we made and then overlay it on the original image

let seam = findSeam(edginessSums: sums, directions: dirs)

var imageMatrix = image.argbBuffer.argb8ToMatrix()
let overlayedMatrix = overlaySeam(seam, on: imageMatrix, color: 0x00FF0000) // draw the seam in bid endian green
let overlayedImage = CGImage.argbFromMatrix(overlayedMatrix)

//: You can see how the green line dodges important parts of the image

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
