/*:
 # Sobel Convolution
 
 To remove the that pixels are unnecessary, we first must find which pixels are necessary.
 
 In this case, necessary means pixels where it would be visually jarring for them to be removed.
 
 Edge detection is able to achieve this, as it is able to detect major changes in color. We will implement this edge detection using an image convolution.
 
 ## What's an Image Convolution?
 
 A convolution is a filter effect for an image that determines the value of each pixel in the new image by adding the weighted values of the neighboring pixels from the original image together.
 
 The effect of a convolution is determined by a matrix of arbitrary size that is passed in, called a kernel.
 
 When the convolution is applied, the center of the kernel is aligned with every pixel of the source image. The red, green, and blue color values are then independently multiplied by the value of the kernel at their position and then added together. Those sums become the RGB values of the pixel positioned at the center of the kernel in the output image.
 
 Depending on the kernel used, convolutions are able to do a wide variety of operations on images, from blurring and sharpening to approximating the derivative.
 
 One example of a kernel is the differentiation kernel, which as it's name suggests approximates the value of the derivative of color at a selected pixel. The kernel for that is as follows:
 
 ```
 Gx = [+1 0 -1]
 Gy = [
    +1
    0
    -1
 ]
 ```
 
 That is able to approximate the derivative at that point because it is effectively taking the delta between the neighboring pixels as (+1)(left) + (-1)(right) = left - right. If the results of the results of the x and y kernels are treated as vector components of a single vector field, it is able to act as a crude gradient operator.
 
 Another would be an averaging kernel, which takes a weighted average of the current pixel and it's vertical neighbors. The kernel for that is as follows:
 
 ```
 Gy = [
    1
    2
    1
 ]
 Gy = [1 2 1]
 ```
 
 ## The Sobel Filter
 
 Now that we have covered the basics of how image convolutions function let's hone in on the specific convolution we will be utilizing for edge detection: the Sobel filter.
 
 The kernel is as follows:
 ```
 Gx = [
    +1 0 -1
    +2 0 -2
    +1 0 -1
 ]
 Gy = [
    +1 +2 +1
     0  0  0
    -1 -2 -1
 ]
 ```
 
 As you may have noticed, the kernel for the Sobel filter is the result of matrix multiplication of the derivative and averaging kernels. That is because the Sobel filter is an improved method to approximate the derivative at each pixel, which will be smoother because it also takes neighboring pixels into account.
 
 ## Implementation
 
 Now that we got this information out of the way let's implement it.
 
 This will use Metal to do the operation because convolutions are a highly regular operation applied to a whole image, so running it on a GPU would provide a significant time and efficiency advantage.
 
 Here is the metal function that will be called to apply the Sobel filter, it is in a comment to it is easily accessible from the main playground page. The actual file is at `/Resources/sobel.metal`. The comments explain what each section is doing.
 ```
 kernel void sobel(
    texture2d<half, access::read> inTexture [[ texture (0) ]],
    texture2d<half, access::write> outTexture [[ texture (1) ]],
    uint2 gid [[ thread_position_in_grid ]]
 ) {
    // define the kernels
    constexpr int kernel_size = 3;
    constexpr int radius = kernel_size / 2;
    half3x3 horizontal_kernel = half3x3(
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1
    );
    half3x3 vertical_kernel = half3x3(
        -1, -2, -1,
        0, 0, 0,
        1, 2, 1
    );

    // march over the image
    // multiply each pixel by it's weight and then add it to the sum for the current pixel
    half3 result_horizontal(0, 0, 0);
    half3 result_vertical(0, 0, 0);
    for (int j = 0; j<= kernel_size - 1; j++) {
        for (int i = 0; i <= kernel_size - 1; i++) {
            uint2 texture_index(gid.x + (i - radius), gid.y + (j + radius));
            result_horizontal += horizontal_kernel[i][j] * inTexture.read(texture_index).rgb;
            result_vertical += vertical_kernel[i][j] * inTexture.read(texture_index).rgb;
        }
    }

    // take the individual rgb results and combine them into a single grayscale channel
    // uses the bt601 standard for the component weights
    half3 bt601 = half3(0.299, 0.587, 0.114);
    half gray_horizontal = dot(result_horizontal.rgb, bt601);
    half gray_vertical = dot(result_vertical.rgb, bt601);

    // find the magnitude of the vector
    half magnitude = length(half2(gray_horizontal, gray_vertical));

    // write it to the output file
    outTexture.write(magnitude, gid);
 }
 ```
 
 Now that we built our Sobel function, let's call it.
 
 */

import Metal
import MetalKit

// get image
let image = NSImage(named: "pom.png")!.cgImage

// calling a metal function has a bit of boilerplate
// so this abstracts it out
// the function can be found at Sources/Sobel.swift
let sobeled = sobel(image)

// now the result of the sobel filter can be viewed in the results view
sobeled

/*:
 Now that we found the edges of the image, we can utilize them to find what to remove.
 
 [Next](@next)
 */
