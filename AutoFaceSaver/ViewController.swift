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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    let stillImageOuput = AVCaptureStillImageOutput()
    var previewLayer: AVCaptureVideoPreviewLayer?

    @IBOutlet var viewLive: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        let devices = AVCaptureDevice.devices()
        println(devices)
        for device in devices{
            if device.hasMediaType(AVMediaTypeVideo){
                if device.position == AVCaptureDevicePosition.Back{
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
                
                //Add VideoDataOutput to capture session for setting delegate (self) for output buffers containing (maybe) face
                let videoOutput = AVCaptureVideoDataOutput()
                captureSession.addOutput(videoOutput)
                videoOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
                
                configureDevice()
                captureSession.startRunning()
                println("Session running")
            }
        }

    }
    
    func configureDevice(){
        captureDevice?.lockForConfiguration(nil)
        captureDevice?.torchMode = .Auto
        captureDevice?.focusMode = .AutoFocus
        captureDevice?.flashMode = .Auto
        captureDevice?.unlockForConfiguration()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /*!
    @method captureOutput:didOutputSampleBuffer:fromConnection:
    @abstract
    Called whenever an AVCaptureVideoDataOutput instance outputs a new video frame.
    
    @param captureOutput
    The AVCaptureVideoDataOutput instance that output the frame.
    @param sampleBuffer
    A CMSampleBuffer object containing the video frame data and additional information about the frame, such as its
    format and presentation time.
    @param connection
    The AVCaptureConnection from which the video was received.
    
    @discussion
    Delegates receive this message whenever the output captures and outputs a new video frame, decoding or re-encoding it
    as specified by its videoSettings property. Delegates can use the provided video frame in conjunction with other APIs
    for further processing. This method will be called on the dispatch queue specified by the output's
    sampleBufferCallbackQueue property. This method is called periodically, so it must be efficient to prevent capture
    performance problems, including dropped frames.
    
    Clients that need to reference the CMSampleBuffer object outside of the scope of this method must CFRetain it and
    then CFRelease it when they are finished with it.
    
    Note that to maintain optimal performance, some sample buffers directly reference pools of memory that may need to be
    reused by the device system and other capture inputs. This is frequently the case for uncompressed device native
    capture where memory blocks are copied as little as possible. If multiple sample buffers reference such pools of
    memory for too long, inputs will no longer be able to copy new samples into memory and those samples will be dropped.
    If your application is causing samples to be dropped by retaining the provided CMSampleBuffer objects for too long,
    but it needs access to the sample data for a long period of time, consider copying the data into a new buffer and
    then calling CFRelease on the sample buffer if it was previously retained so that the memory it references can be
    reused.
    */
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!){
        println("Recieved output sample buffer \(NSDate())")
    }
}

