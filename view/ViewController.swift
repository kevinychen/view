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
    var iVideoPreviewLayer: AVCaptureVideoPreviewLayer?

    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        print("\(OpenCVWrapper.openCVVersionString())")

        imageView.isHidden = true

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
        iVideoPreviewLayer = videoPreviewLayer

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
        photoSettings.flashMode = .off
        iCapturePhotoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            return print("failed to get image data")
        }
        guard let capturedImage = UIImage.init(data: imageData, scale: 1.0) else {
            return print("failed to capture image")
        }
        print(capturedImage.debugDescription)
        sendToServer(data: UIImageJPEGRepresentation(capturedImage, 1.0)!)
    }

    func sendToServer(data: Data) {
        imageView.image = UIImage(data: data)
        imageView.isHidden = false
        takePhotoButton.isHidden = true
        activityIndicator.startAnimating()

        addPiece(data: data) {
            getPieceImage() {
                DispatchQueue.main.async {
                    self.imageView.isHidden = true
                    self.takePhotoButton.isHidden = false
                    self.activityIndicator.stopAnimating()
                    self.performSegue(withIdentifier: "ToSecondView", sender: self)
                }
            }
        }
    }
}
