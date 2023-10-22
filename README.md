### Steps

1. Understanding Data Set
2. Slicing the Images
3. Training Using CreateML
4. Integrating Model with App

### Dataset

https://quickdraw.withgoogle.com/data

https://github.com/googlecreativelab/quickdraw-dataset

### Split Images using online tool

https://pinetools.com/

-> Take an image and split Images

### Swigt Code

- Canvas

```swift
import Foundation
import UIKit

class Canvas: UIView {

    var startingPoint: CGPoint = CGPoint.zero
    var currentPoint: CGPoint = CGPoint.zero
    var path: UIBezierPath!


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch = touches.first else {
            return
        }

        self.startingPoint = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touch = touches.first else {
            return
        }

        self.currentPoint = touch.location(in: self)
        self.path = UIBezierPath()
        self.path.move(to: startingPoint)
        self.path.addLine(to: currentPoint)

        self.startingPoint = self.currentPoint

        self.drawShapeLayer()
    }

    private func drawShapeLayer() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 2.0
        self.layer.addSublayer(shapeLayer)
        self.setNeedsDisplay()
    }

    func clear() {
        self.path.removeAllPoints()
        self.layer.sublayers = nil
        self.setNeedsDisplay()
    }
}

```

- Extensions

```swift

extension UIView {

    func uiImage() -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        return renderer.image { (context) in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }

    }

}

extension UIImage {

    func resizeTo(size :CGSize) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }

    func toBuffer() -> CVPixelBuffer? {

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

}

```

- ViewController

```swift

import UIKit
import CoreML

class ViewController: UIViewController {

    let canvas = Canvas()
    private var model: DrawingClassifier? {
        try? DrawingClassifier(configuration: MLModelConfiguration())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.canvas.frame = view.frame
        self.view.addSubview(canvas)
    }

    @IBAction private func clear() {
        self.title = ""
        self.canvas.clear()
    }

    @IBAction private func classify() {

        let image = self.canvas.uiImage()
        guard
            let resizedImage = image.resizeTo(size: CGSize(width: 299, height: 299)),
            let model = self.model,
            let buffer = resizedImage.toBuffer(),
            let output = try? model.prediction(image: buffer)
        else { return }
        DispatchQueue.main.async {
            self.title = output.classLabel
        }
    }


}


```
