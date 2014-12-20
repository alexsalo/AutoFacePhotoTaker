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

class ViewController: UIViewController {
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    let stillImageOuput = AVCaptureStillImageOutput()
    var assetCollection: PHAssetCollection!
    var faceDetector: CIDetector?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var orientation: UIImageOrientation = .Up

    @IBOutlet var viewLive: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        let devices = AVCaptureDevice.devices()
        println(devices)
        for device in devices{
            if device.hasMediaType(AVMediaTypeVideo){
                if device.position == AVCaptureDevicePosition.Front{
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
                var rootLayer = self.view.layer
                rootLayer.masksToBounds = true
                var frame = self.viewLive.frame
                previewLayer.frame = frame
                rootLayer.insertSublayer(previewLayer, atIndex: 0)
                
                var settings: NSDictionary = [AVVideoCodecKey: AVVideoCodecJPEG]
                stillImageOuput.outputSettings = settings
                captureSession.addOutput(stillImageOuput)
                
                captureSession.startRunning()
                println("Session running")
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

