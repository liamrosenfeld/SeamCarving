/*:
 # Everything
 
 Now that we have covered how the seam carving algorithm works, here's a live view to play with.
 
 I initially wrote this code in a Xcode project to be able to debug and profile. However, it runs significantly slower in playgrounds because it uses a debug build instead of a release build. Code that would take 100 milliseconds instead takes 8 seconds. I do not know of any way around this, so I just advise to not remove too many pixels and to keep the sobelPer value on the high side.
 
 Feel free to try this out on your own images! Just drag them into the images folder of the global resources folder and then run this page.
 
 The code for the live view can be found in the sources folder of this page.
 */

import PlaygroundSupport
PlaygroundPage.current.setLiveView(SeamCarvingView())

/*:
 Thank you for checking out my playground. I hope you enjoyed it as much as I enjoyed making it!
 
 ## Main Sources
 
 * [Seam Carving for Content-Aware Image Resizing by Shai Avidan and Ariel Shamir](https://perso.crans.org/frenoy/matlab2012/seamcarving.pdf) (Original paper on the topic)
 * [MIT 18.S191](https://computationalthinking.mit.edu/Fall20/)
 * [Image Convolution Slides from Portland State University](http://web.pdx.edu/~jduh/courses/Archive/geog481w07/Students/Ludwig_ImageConvolution.pdf)
 
 I'd like to thank all of my teachers for helping me explore these new worlds.
 
 ### Image Attributions
 
 * The Persistence of Memory
 * By Broadway_tower.jpg: Newton2 at en.wikipediaderivative work: Damir-NJITWILL (talk) - Broadway_tower.jpg, CC BY 2.5, https://commons.wikimedia.org/w/index.php?curid=12125976
 * Tree from Adobe Stock
 
 All others were made by me
 
 */
