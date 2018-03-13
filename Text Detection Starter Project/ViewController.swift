//
//  ViewController.swift
//  Text Detection Starter Project
//
//  Created by Sai Kambampati on 6/21/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    lazy var ocrRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for:OCR().model)
            return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
        }
        catch{
            fatalError("Cannot load model")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startLiveVideo()
        startTextDetection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startLiveVideo() {
        //1
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        //2
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        //3
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
        
        session.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        let result = observations.map({$0 as? VNTextObservation})
        DispatchQueue.main.async() {
            print("\(Date()): dispatch queue...")
            self.imageView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {
                    continue
                }
                
                self.highlightWord(box: rg)
                self.doOCR(box: rg)
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
        }
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * imageView.frame.size.width
        let yCord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width
        let height = (minY - maxY) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        imageView.layer.addSublayer(outline)
    }
    
    func highlightLetters(box: VNRectangleObservation) {
        let xCord = box.topLeft.x * imageView.frame.size.width
        let yCord = (1 - box.topLeft.y) * imageView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * imageView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        imageView.layer.addSublayer(outline)
    }
    func handleClassification(request: VNRequest, error: Error?)
    {
        guard let observations = request.results as? [VNClassificationObservation]
            else {fatalError("unexpected result") }
        guard let best = observations.first
            else { fatalError("cant get best result")}
        
        //ON MAIN-QUEUE
        DispatchQueue.main.async {
            
            //BEST.IDENTIFIER IS OUR PREDICTION WITH HIGHEST CONFIDENCE !
            print("recognized: " + best.identifier)
            
        }
    }
    
    func doOCR(box: VNTextObservation){
        guard let boxes = box.characterBoxes else {
            return
        }
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * imageView.frame.size.width
        let yCord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width
        let height = (minY - maxY) * imageView.frame.size.height
        
        guard let img = self.imageView.image
            else{
                return
        }
        
        guard let inputImg:CIImage = CIImage(image: img)
            else{
                return
        }
        
//        //LETS LOAD AN IMAGE FROM RESOURCE (TRY ANOTHER ONE ...)
//        let ourFirstImage:UIImage = UIImage(named: "7.PNG")!
//
//        //WE NEED AN CIIMAGE - NO NEED TO SCALE
//        let ourInput:CIImage = CIImage(image:ourFirstImage)!
//
        //PREPARE THE HANDLER
        let handler = VNImageRequestHandler(ciImage: inputImg.cropped(to: CGRect(x: xCord, y: yCord, width: width, height: height)), options: [:])
        
        //SOME OPTIONS (TO PLAY WITH..)
        self.ocrRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill
        
        //FEED IT TO THE QUEUE
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try  handler.perform([self.ocrRequest])
            } catch {
                print ("Error")
            }
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}
