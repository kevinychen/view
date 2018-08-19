//
//  Utils.swift
//  view
//
//  Created by Kevin Chen on 8/18/18.
//  Copyright © 2018 Kevin Chen. All rights reserved.
//

struct Constants {
    static let SERVER = "http://192.168.0.2:8080"
    static let NUM_ROWS = 29
    static let NUM_COLS = 15
}

struct State {
    static var pieceId: String?

    // bytes of processed JPG image (with jigsaw piece sides highlighted)
    static var parsedImageData: Data?

    // whether the client is sending input positions (instead of asking the server to guess)
    static var sendInputPosition: Bool = true

    static var rowCoordinate: Int = 0
    static var colCoordinate: Int = 0
}

func addPiece(data: Data, completionHandler: @escaping () -> Void) {
    guard let url: URL = URL(string: "\(Constants.SERVER)/piece") else {
        return print("invalid URL")
    }

    var request: URLRequest = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = "Boundary-\(NSUUID().uuidString)"
    request.setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")

    let fullData = photoDataToFormData(data: data, boundary: boundary, fileName: "name")
    request.setValue(String(fullData.count), forHTTPHeaderField: "Content-Length")

    request.httpBody = fullData
    request.httpShouldHandleCookies = false

    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: request) { (data, response, error) in
        guard let addPieceResponse = data else {
            print(error ?? "error when calling server")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: addPieceResponse, options: []) else {
            print("failed to deserialize server response")
            return
        }
        State.pieceId = (json as! Dictionary<String, String>)["pieceId"]
        completionHandler()
    }
    task.resume()
}

func getPieceImage(completionHandler: @escaping () -> Void) {
    guard let pieceId = State.pieceId else {
        print("no piece ID set")
        return
    }
    guard let url: URL = URL(string: "\(Constants.SERVER)/piece/\(pieceId)/image") else {
        return print("invalid URL")
    }

    var request: URLRequest = URLRequest(url: url)
    request.httpMethod = "GET"

    request.httpShouldHandleCookies = false

    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: request) { (data, response, error) in
        State.parsedImageData = data
        completionHandler()
    }
    task.resume()
}

private func photoDataToFormData(data: Data, boundary:String, fileName:String) -> Data {
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
