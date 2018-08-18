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

        print("\(OpenCVWrapper.openCVVersionString())")

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
        guard let url: URL = URL(string: "\(Constants.SERVER)/upload") else {
            return print("invalid URL")
        }

        var request1: URLRequest = URLRequest(url: url)

        request1.httpMethod = "POST"

        let boundary = "Boundary-\(NSUUID().uuidString)"
        request1.setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")

        let fullData = photoDataToFormData(data: data, boundary: boundary, fileName: "name")
        request1.setValue(String(fullData.count), forHTTPHeaderField: "Content-Length")

        request1.httpBody = fullData
        request1.httpShouldHandleCookies = false

        print("sending")
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request1) { (data, response, error) in
            print("response")
            print(data)
            print(response)
            print(error)
            State.parsedImageData = data
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "ToSecondView", sender: self)
            }
        }
        task.resume()
    }

    func photoDataToFormData(data: Data, boundary:String, fileName:String) -> Data {
        var fullData = Data()

        let lineOne = "--" + boundary + "\r\n"
        fullData.append(lineOne.data(using: String.Encoding.utf8, allowLossyConversion: false)!)

        let lineTwo = "Content-Disposition: form-data; name=\"file\"; filename=\"" + fileName + "\"\r\n"
        fullData.append(lineTwo.data(using: String.Encoding.utf8, allowLossyConversion: false)!)

        let lineThree = "Content-Type: image/jpg\r\n\r\n"
        fullData.append(lineThree.data(using: String.Encoding.utf8, allowLossyConversion: false)!)

        fullData.append(data)

        let lineFive = "\r\n"
        fullData.append(lineFive.data(using: String.Encoding.utf8, allowLossyConversion: false)!)

        let lineSix = "--" + boundary + "--\r\n"
        fullData.append(lineSix.data(using: String.Encoding.utf8, allowLossyConversion: false)!)

        return fullData
    }
}
