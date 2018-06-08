//
//  ViewController.swift
//  view
//
//  Created by Kevin Chen on 6/6/18.
//  Copyright © 2018 Kevin Chen. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {

    var iCapturePhotoOutput: AVCapturePhotoOutput?

    @IBOutlet weak var cameraView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            fatalError("No video capture device")
        }

        let captureSession = AVCaptureSession()
        let capturePhotoOutput = AVCapturePhotoOutput()
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input);
        } catch {
            print(error)
        }
        captureSession.addOutput(capturePhotoOutput)
        iCapturePhotoOutput = capturePhotoOutput

        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = cameraView.bounds
        cameraView.layer.addSublayer(videoPreviewLayer)

        captureSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func takePhotoButton(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        iCapturePhotoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        guard let capturedImage = UIImage.init(data: imageData, scale: 1.0) else {
            return
        }
        print(capturedImage.debugDescription)
    }
}
