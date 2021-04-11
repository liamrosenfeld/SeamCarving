import Accelerate.vImage

public extension vImage_Buffer {
    func planarToMatrix() -> [[UInt8]] {
        // Int width instead of UInt
        let width = Int(self.width)
        let height = Int(self.height)
        
        // values to navigate the buffer
        let totalBytes = height * self.rowBytes
        let totalPixelRoom = self.rowBytes * height
        
        // get buffer pointer from raw buffer
        let dataPtr = self.data.bindMemory(to: UInt8.self, capacity: totalBytes)
        let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: totalPixelRoom)
        
        // copy content over
        // doing each row separately is necessary to remove dead-space at the end of each row
        var pixels: [[UInt8]] = zeros(width: width, height: height)
        for row in 0..<height {
            let rowStart = row * self.rowBytes
            let rowEnd   = rowStart + width
            let rowSlice = dataBuffer[rowStart..<rowEnd]
            pixels[row] = Array(rowSlice)
        }
        return pixels
    }
    
    func argb8ToMatrix() -> [[UInt32]] {
        // Int width instead of UInt
        let width = Int(self.width)
        let height = Int(self.height)
        
        // values to navigate the buffer
        let totalBytes = height * self.rowBytes
        let rowPixelRoom =  self.rowBytes / 4
        let totalPixelRoom = rowPixelRoom * height
        
        // get buffer pointer from raw buffer
        let dataPtr = self.data.bindMemory(to: UInt32.self, capacity: totalBytes)
        let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: totalPixelRoom)
        
        // copy content over
        // doing each row separately is necessary to remove dead-space at the end of each row
        var pixels: [[UInt32]] = zeros(width: width, height: height)
        for row in 0..<height {
            let rowStart = row * rowPixelRoom
            let rowEnd   = rowStart + width
            let rowSlice = dataBuffer[rowStart..<rowEnd]
            pixels[row] = Array(rowSlice)
        }
        return pixels
    }
}
