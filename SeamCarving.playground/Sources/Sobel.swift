import Metal
import MetalKit

fileprivate let device = MTLCreateSystemDefaultDevice()!

fileprivate var sobelPipeline: MTLComputePipelineState = {
    let library = device.makeDefaultLibrary()!
    let function = library.makeFunction(name: "sobel")!
    let pipeline = try! device.makeComputePipelineState(function: function)
    return pipeline
}()

// MARK: - Sobel
public func sobel(_ image: CGImage) -> CGImage {
    let queue  = device.makeCommandQueue()!
    
    // get input texture
    let textureLoader = MTKTextureLoader(device: device)
    let inputTexture = try! textureLoader.newTexture(cgImage: image)
    
    // make output texture
    let textureDescriptor = inputTexture.matchingDescriptor()
    textureDescriptor.pixelFormat = .r32Float
    textureDescriptor.usage = [.shaderRead, .shaderWrite]
    let outputTexture = device.makeTexture(descriptor: textureDescriptor)!
    
    // create kernel
    let buffer = queue.makeCommandBuffer()!
    
    // encode kernal
    let encoder = buffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(sobelPipeline)
    encoder.setTexture(inputTexture, index: 0)
    encoder.setTexture(outputTexture, index: 1)
    
    // set threadgroups
    let threadsPerThreadGroup = MTLSize(width: 16, height: 16, depth: 1)
    let threadgroupsPerGrid = MTLSize(width: inputTexture.width/16 + 1, height: inputTexture.height/16 + 1, depth: 1)
    encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    encoder.endEncoding()
    
    // run
    buffer.commit()
    buffer.waitUntilCompleted()
    
    // get results
    let ciImg = CIImage(mtlTexture: outputTexture, options: [.colorSpace: CGColorSpaceCreateDeviceGray()])!.oriented(.downMirrored)
    return ciImg.cgImage!
}
