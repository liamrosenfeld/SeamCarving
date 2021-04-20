import SwiftUI
import AppKit

public struct SeamCarvingView: View {
    @State var origImage: NSImage
    @State var dispImage: NSImage
    @State var carved: NSImage?
    
    @State var imageOptions: [ImageFile]
    @State var selectedImage: ImageFile
    
    @State var newWidth: Int
    @State var sobelPer: Int
    
    @State var origWidth: Int
    @State var currentWidth: Int
    
    @State var computing = false
    
    let interGen: IntermediateGenerator
    
    public init() {
        // set picker options
        let imageNames = ImageFile.getAll()
        self._imageOptions = State(initialValue: imageNames)
        self._selectedImage = State(initialValue: imageNames.first!)
        
        // set images
        let image = imageNames.first!.scaledArgbImage()!
        self._origImage = State(initialValue: image)
        self._dispImage = _origImage
        self._origWidth = State(initialValue: Int(image.realSize.width))
        
        self.interGen = IntermediateGenerator(for: image.cgImage)
        self._currentWidth = _origWidth
        
        // set carve seam options to default
        self._newWidth = _origWidth
        self._sobelPer = State(initialValue: 20)
    }
    
    public var body: some View {
        VStack {
            Image(nsImage: dispImage)
                .frame(width: 350, height: 350)
            
            HStack {
                Text("Original Width: \(Int(origImage.size.width))")
                Text("Current Width: \(currentWidth)")
            }
            
            Divider()
            
            Picker("Image", selection: $selectedImage.onChange(updateImage)) {
                ForEach(imageOptions, id: \.self) { file in
                    Text(file.name).tag(file)
                }
            }
            .frame(maxWidth: 200)
            
            Button("Show Original", action: showOrig)
            
            Divider()
            
            Group {
                Text("Show Intermediate Steps")
                HStack {
                    Button("Sobel")         { setDist(to: interGen.sobeled()) }
                    Button("Sum")           { setDist(to: interGen.sums()) }
                    Button("Directions")    { setDist(to: interGen.directions()) }
                }
                HStack {
                    Button("Seam on Sum")   { setDist(to: interGen.seamOnSum()) }
                    Button("Seam on Sobel") { setDist(to: interGen.seamOnSobel()) }
                    Button("Seam on Orig")  { setDist(to: interGen.seamOnOrig()) }
                }
            }
            
            Divider()
            
            Group {
                Text("Carve Seams")
                HStack {
                    NumberField("Width", value: $newWidth, range: 1...origWidth)
                    NumberField("Sobel Per", value: $sobelPer, range: 1...newWidth)
                }
                HStack {
                    Button("Apply", action: applyWidth)
                        .disabled(computing)
                    Button("Show Again (no recompute)", action: showAgain)
                }
            }
        
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor.cgColor))
    }
    
    // MARK: - Setting Image
    func updateImage(_ newSelection: ImageFile) {
        // get argb8 image of desired size
        guard let newImage = newSelection.scaledArgbImage() else {
            print("image was invalid")
            return
        }
        
        // set images
        origImage = newImage
        dispImage = newImage
        interGen.image = newImage.cgImage
        
        // set widths
        origWidth = Int(newImage.realSize.width)
        newWidth  = origWidth
        currentWidth = origWidth
    }
    
    // MARK: - Buttons
    func applyWidth() {
        computing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let cgImage: CGImage = {
                if sobelPer == 1 {
                    // recompute sobel every time
                    return carveImage(origImage.cgImage, width: newWidth)
                } else if sobelPer / newWidth != 1 {
                    // if there will be more than one sobel, use balanced
                    return balancedCarveImage(origImage.cgImage, width: newWidth, sobelPer: sobelPer)
                } else {
                    // use one sobel
                    return sharedCarveImage(origImage.cgImage, width: newWidth)
                }
            }()
            
            let newSize = NSSize(width: newWidth, height: cgImage.height)
            let nsImage = NSImage(cgImage: cgImage, size: newSize)
            
            DispatchQueue.main.async {
                dispImage = nsImage
                carved = nsImage
                currentWidth = newWidth
                computing = false
            }
        }
    }
    
    func showAgain() {
        if let carved = carved {
            dispImage = carved
        }
    }
    
    func showOrig() {
        dispImage = origImage
    }
    
    func setDist(to image: CGImage) {
        dispImage = NSImage(cgImage: image, size: origImage.realSize)
    }
}

