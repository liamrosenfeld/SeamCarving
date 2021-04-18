/*:
 # Image Seam Carving
 
 Hello! I'm Liam Rosenfeld. I'm a 12th grader from Florida and this is my WWDC21 Swift Student Challenge submission.
 
 Over the past two years, I have had a great time exploring signal processing through my two successful scholarship applications. Last year, that exploration introduced me to Accelerate and I immediately went down the rabbit hole of learning about its other capabilities. I started learning about vImage, and updated my app, Image to ASCII Art, to utilize it (resulting in a noticeable speed up). As I learned more about images, I came across the seam carving algorithm online and instantly was drawn to it because of how it utilizes math to a way that feels magical.
 
 Seam carving is a method of content-aware resizing images. That means it is able to change the aspect ratio of an image without resulting in visually unpleasant squashing.
 
 It is able to achieve that by intelligently removing pixels from inside the image that it determines are not necessary. This algorithm includes many steps, and these will be a page of this playground dedicated to each with a detailed explanation of the code.
 
 I hope that this playground is able to showcase both the interesting application and implementation of this algorithm.
 
 Now without further ado, let's dig into this together.
 
 Note:
 - Some pages may take a couple seconds to run because there are some computation heavy operations. The results view will update during, so you would be able to tell the difference between computing and playgrounds hanging.
 - Due to the highly iterative nature of some code in this playground, the results sidebar would slow it down dramatically. For that reason, code is sometimes explained and then run from somewhere else. This is often done by prefixing functions on the page with an underscore and then calling one without.
 - A good amount of code that is unnecessary for understanding the central algorithm is abstracted away as functions. If you would like to see it, you can either jump to definition or look through the global sources folder of the playground.
 
 _(To skip the explanation pages, jump to the [last page](Everything))_
 
 [Next](@next)
 
 */

