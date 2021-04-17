//
//  Sums.swift
//  tester
//
//  Created by Liam Rosenfeld on 4/10/21.
//

import Accelerate.vImage

public func intensitySums(buffer: vImage_Buffer) -> (intensitySums: [[UInt32]], directions: [[Int8]]) {
    // make blank arrays of the appropriate size to store the output
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    
    // the values of path of least energy
    // max vertical resolution is 2^32/2^8 = 16,777,216
    // because that would be the amount of pixels it would take to overflow if every pixel of the edge detection is maxed out
    var intensitySums: [[UInt32]] = zeros(width: width, height: height)
    // the direction to the least point of least energy below (-1: left, 0: center, 1: right)
    var directions: [[Int8]] = zeros(width: width, height: height)
    
    // util to be able to iterate over the vImage buffer
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
            // get min of the the three values below the current pixel
            // if values are out of bounds the center value is used (that is what the min and maxes are doing)
            // our custom min function ignores them if they have the same value as the center
            let (minBelow, minIndex) = minWithIndex(
                intensitySums[row + 1][max(col - 1, 0)],
                intensitySums[row + 1][col],
                intensitySums[row + 1][min(col + 1, width - 1)]
            )
            
            // add together lowest intensity below and intensity of current pixel
            let intensityForThisPixel = UInt32(dataBuffer[rowStart + col]) // cast up to prevent overflow when adding
            intensitySums[row][col] = minBelow + intensityForThisPixel
            
            // add direction to the array
            directions[row][col] = minIndex - 1
        }
    }
    
    return (intensitySums, directions)
}

public func intensitySums(intensities: [[UInt8]]) -> (intensitySums: [[UInt32]], directions: [[Int8]]) {
    // make blank arrays of the appropriate size to store the output
    let width = intensities[0].count
    let height = intensities.count
    
    // the values of path of least energy
    // max vertical resolution is 2^32/2^8 = 16,777,216
    // because that would be the amount of pixels it would take to overflow if every pixel of the edge detection is maxed out
    var intensitySums: [[UInt32]] = zeros(width: width, height: height)
    // the direction to the least point of least energy below (-1: left, 0: center, 1: right)
    var directions: [[Int8]] = zeros(width: width, height: height)
    
    // the bottom row is the same (no intensities below to add to it) so it can be copied over
    for col in 0..<width {
        intensitySums[height-1][col] = UInt32(intensities[height - 1][col])
    }
    
    // adds from the bottom up, so it goes in reverse order
    // skips the very bottom row because it was already copied over
    for row in (0..<height-1).reversed() {
        for col in 0..<width {
            // get min of the the three values below the current pixel
            // if values are out of bounds the center value is used (that is what the min and maxes are doing)
            // our custom min function ignores them if they have the same value as the center
            let (minBelow, minIndex) = minWithIndex(
                intensitySums[row + 1][max(col - 1, 0)],
                intensitySums[row + 1][col],
                intensitySums[row + 1][min(col + 1, width - 1)]
            )
            
            // add together lowest intensity below and intensity of current pixel
            let intensityForThisPixel = UInt32(intensities[row][col]) // cast up to prevent overflow when adding
            intensitySums[row][col] = minBelow + intensityForThisPixel
            
            // add direction to the array
            directions[row][col] = minIndex - 1
        }
    }
    
    return (intensitySums, directions)
}

// prefers the middle column if they are the same
func minWithIndex(_ val0: UInt32, _ val1: UInt32, _ val2: UInt32) -> (val: UInt32, index: Int8) {
    var index: Int8 = 1
    var min = val1
    if val0 < min {
        index = 0
        min = val0
    }
    if val2 < min {
        index = 2
        min = val2
    }
    return (min, index)
}

// this could be implemented as a shader
// but it is only run once so that would not have a big impact on the playground experience
public func directionsToColorMatrix(_ directions: [[Int8]]) -> [[UInt32]] {
    var matrix: [[UInt32]] = zeros(width: directions[0].count, height: directions.count)
    
    for row in 0..<directions.count {
        for col in 0..<directions[0].count {
            let direction = directions[row][col]
            if direction == -1 {
                matrix[row][col] = 0x0000FF00 // big endian red
            } else if direction == 0 {
                matrix[row][col] = 0x00FF0000 // big endian green
            } else if direction == 1 {
                matrix[row][col] = 0xFF000000 // big endian blue
            }
        }
    }
    
    return matrix
}
