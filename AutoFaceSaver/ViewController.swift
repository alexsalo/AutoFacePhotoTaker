//
//  ViewController.swift
//  AutoFaceSaver
//
//  Created by Aleksandr Salo on 12/19/14.
//  Copyright (c) 2014 Aleksandr Salo. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreMedia
import AssetsLibrary
import CoreGraphics
import Foundation
import CoreLocation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    let stillImageOutput = AVCaptureStillImageOutput()
    var videoConnection: AVCaptureConnection?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var detector: CIDetector?
    var library: ALAssetsLibrary?
    var softwareContext: CIContext?
    let albumName = "lostFaces"

    @IBOutlet var viewLive: UIView!
    
    @IBAction func tap_liveView(sender: AnyObject) {
        println("tap")
        self.takePhoto()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        let devices = AVCaptureDevice.devices()
        println(devices)
        for device in devices{
            if device.hasMediaType(AVMediaTypeVideo){
                if device.position == AVCaptureDevicePosition.Back
                {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        if captureDevice != nil{
            var err : NSError? = nil
            captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
            if err != nil{
                println("eroor: \(err?.localizedDescription)")
            }
            
            if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession){
                previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer.frame = self.viewLive.frame
                self.view.layer.masksToBounds = true
                self.view.layer.insertSublayer(previewLayer, atIndex: 0)
                
                //add still output to capture photo
                var settings: NSDictionary = [AVVideoCodecKey: AVVideoCodecJPEG]
                stillImageOutput.outputSettings = settings
                captureSession.addOutput(stillImageOutput)
                
                //Add VideoDataOutput to capture session for setting delegate (self) for output buffers containing (maybe) face
                let videoOutput = AVCaptureVideoDataOutput()
                captureSession.addOutput(videoOutput)
                videoOutput.setSampleBufferDelegate(self, queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
                
                //confid device and start session
                if captureDevice?.position == AVCaptureDevicePosition.Back{
                    configureDevice()
                }
                
                //config library to save photos
                library = ALAssetsLibrary()
                softwareContext = CIContext(options: [kCIContextUseSoftwareRenderer: true])
                
                configureFaceDetector()
                captureSession.startRunning()
                println("Session running")
                
                self.videoConnection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
            }
        }

    }
    
    func configureDevice(){
        captureDevice?.lockForConfiguration(nil)
        captureDevice?.torchMode = .Auto
        captureDevice?.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
        captureDevice?.flashMode = AVCaptureFlashMode.Auto
        captureDevice?.unlockForConfiguration()
    }
    
    func configureFaceDetector(){
        self.detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [
                CIDetectorAccuracy: CIDetectorAccuracyLow,
                CIDetectorTracking: false,
                CIDetectorMinFeatureSize: NSNumber(float: 0.1)
            ])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func takePhoto(){
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
            (imageSampleBuffer : CMSampleBuffer!, _) in
            println("image captured")
            let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
            let ciImage = CIImage(data: imageDataJpeg)
            let cgImage = self.softwareContext!.createCGImage(ciImage, fromRect: ciImage.extent())
            self.library!.writeImageToSavedPhotosAlbum(cgImage, metadata: ciImage.properties(), completionBlock: nil)
            println("image saved")
        }
    }

//delegate method
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        println("Recieved output sample buffer \(NSDate())")
        
        //get image
        let pb = CMSampleBufferGetImageBuffer(sampleBuffer)
        let ciImage = CIImage(CVPixelBuffer: pb)
        
        let exifOrientation = 6
        let feature_options = [CIDetectorImageOrientation: exifOrientation]

        let features = self.detector!.featuresInImage(ciImage!, options: feature_options) as [CIFaceFeature]
        if features.count > 0 {
            println("faces detected \(NSDate())")
            let feature = features[0]
            //println(feature.bounds)
            //println(ciImage.extent())
            
            //Here could be used saving from the buffer that is already at hands, but fir some reason it's hard to do - errors
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {self.takePhoto()})
        }
    }
    

}

