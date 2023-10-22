//
//  ViewController.swift
//  DrawingApp
//
//  Created by Mohammad Azam on 3/4/20.
//  Copyright © 2020 Mohammad Azam. All rights reserved.
//

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

