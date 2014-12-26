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

let albumName = "lostFaces"

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    let stillImageOutput = AVCaptureStillImageOutput()
    var videoConnection: AVCaptureConnection?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var detector: CIDetector?
    var library: ALAssetsLibrary?
    var softwareContext: CIContext?
    
    //album
    var albumFound: Bool = false
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult!
    let fetchOptions = PHFetchOptions()

    @IBOutlet var viewLive: UIView!
    
    @IBAction func tap_liveView(sender: AnyObject) {
        println("tap")
        self.takePhoto()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.findOrCreateAppAlbum()
        
        //find capture device
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
            
            //save to "saved photos" or app specific album
            self.saveImageToAppAlbum(imageDataJpeg)
            //self.saveImageToSavedPhotosAlbum(imageDataJpeg)
            
            println("image saved")
        }
    }
    
    func saveImageToSavedPhotosAlbum(imageData: NSData){
        let ciImage = CIImage(data: imageData)
        let cgImage = self.softwareContext!.createCGImage(ciImage, fromRect: ciImage.extent())
        self.library!.writeImageToSavedPhotosAlbum(cgImage, metadata: ciImage.properties(), completionBlock: nil)
    }
    
    func saveImageToAppAlbum(imageData: NSData){
        //they still appear in camera roll and recently saved - that's design, babe
        let uiImage = UIImage(data: imageData)
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(uiImage)
            let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset)
            albumChangeRequest.addAssets([assetPlaceholder])
            }, completionHandler: {(success, error)in NSLog("Adding Image to Library -> %@", (success ? "Sucess":"Error!"))
        })
    }
    
    func findOrCreateAppAlbum(){
        //Check if the folder exists, if not, create it
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        //if we fetched something - we have album
        if let first_Obj:AnyObject = collection.firstObject{
            self.albumFound = true
            self.assetCollection = first_Obj as PHAssetCollection
        }else{
            //Album placeholder for the asset collection, used to reference collection in completion handler
            var albumPlaceholder:PHObjectPlaceholder!
            //create the folder
            NSLog("\nFolder \"%@\" does not exist\nCreating now...", albumName)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumName)
                albumPlaceholder = request.placeholderForCreatedAssetCollection
                },
                completionHandler: {(success:Bool, error:NSError!)in
                    NSLog("Creation of folder -> %@", (success ? "Success":"Error!"))
                    self.albumFound = (success ? true:false)
                    if(success){
                        let collection = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([albumPlaceholder.localIdentifier], options: nil)
                        self.assetCollection = collection?.firstObject as PHAssetCollection
                    }
            })
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
            
            //Here could be used saving from the buffer that is already at hands, but for some reason it's hard to do - errors
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {self.takePhoto()})
        }
    }
    

}

