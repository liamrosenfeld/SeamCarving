import Foundation

public func findSeam(edginessSums: [[UInt32]], directions: [[Int8]]) -> [Int] {
    var seam: [Int] = Array(repeating: 0, count: edginessSums.count)
    
    let start = edginessSums[0].enumerated().min { $0.element < $1.element }!.offset
    seam[0] = start
    
    var col = start
    for row in 1..<directions.count {
        col += Int(directions[row][col])
        seam[row] = col
    }
    
    return seam
}

public func overlaySeam<T>(_ seam: [Int], on matrix: [[T]], color: T) -> [[T]] {
    var matrix = matrix
    for row in 0..<seam.count {
        let col = seam[row]
        matrix[row][col] = color
    }
    return matrix
}

public func removeSeam<T>(_ seam: [Int], from matrix: inout [[T]]) {
    for row in 0..<seam.count {
        let col = seam[row]
        matrix[row].remove(at: col)
    }
}

public func removeSeam<T>(_ seam: [Int], from matrix: [[T]]) -> [[T]] {
    var matrix = matrix
    for row in 0..<seam.count {
        let col = seam[row]
        matrix[row].remove(at: col)
    }
    return matrix
}
