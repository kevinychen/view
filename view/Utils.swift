//
//  Utils.swift
//  view
//
//  Created by Kevin Chen on 8/18/18.
//  Copyright © 2018 Kevin Chen. All rights reserved.
//

struct Constants {
    static let SERVER = "http://192.168.0.43:8080"
    static let NUM_ROWS = 60
    static let NUM_COLS = 84
}

struct State {
    static var pieceId: String?

    static var imageData: Data?

    static var piece: Piece?

    // whether the client is sending input positions (instead of asking the server to guess)
    static var sendInputPosition: Bool = true

    static var rowCoordinate: Int = 0
    static var colCoordinate: Int = 0

    static var suggestions: [Suggestion] = []
}

struct Point: Codable {
    let x: Int
    let y: Int
}

struct Side: Codable {
    let points: [Point]
}

struct Piece: Codable {
    let sides: [Side]
}

let DIRECTIONS = ["right-side up", "rotated left", "upside-down", "rotated right"]

struct Suggestion: Codable, CustomStringConvertible {
    let row: Int
    let col: Int
    let dir: Int
    let score: Double

    var description: String {
        return "(\(row), \(col)) \(DIRECTIONS[dir]) (\(score))"
    }
}

struct AddPieceResponse: Codable {
    let pieceId: String
}

struct SavePieceRequest: Codable {
    let row: Int?
    let col: Int?
    let dir: Int?
    let flip: Bool
}

struct SavePieceResponse: Codable {
    let suggestions: [Suggestion]
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
        guard let json = data else {
            print(error ?? "error when calling server")
            return
        }
        guard let addPieceResponse = try? JSONDecoder().decode(AddPieceResponse.self, from: json) else {
            print("failed to deserialize server response")
            return
        }
        State.pieceId = addPieceResponse.pieceId
        completionHandler()
    }
    task.resume()
}

func getPiece(completionHandler: @escaping () -> Void) {
    guard let pieceId = State.pieceId else {
        print("no piece ID set")
        return
    }
    guard let url: URL = URL(string: "\(Constants.SERVER)/piece/\(pieceId)") else {
        return print("invalid URL")
    }

    var request: URLRequest = URLRequest(url: url)
    request.httpMethod = "GET"

    request.httpShouldHandleCookies = false

    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: request) { (data, response, error) in
        guard let json = data else {
            print(error ?? "error when calling server")
            return
        }
        guard let piece = try? JSONDecoder().decode(Piece.self, from: json) else {
            print("failed to deserialize server response")
            return
        }
        State.piece = piece
        completionHandler()
    }
    task.resume()
}

func processPiece(flip: Bool, completionHandler: @escaping () -> Void) {
    guard let pieceId = State.pieceId else {
        print("no piece ID set")
        return
    }
    guard let url: URL = URL(string: "\(Constants.SERVER)/piece/\(pieceId)/process") else {
        return print("invalid URL")
    }

    var request: URLRequest = URLRequest(url: url)
    request.httpMethod = "POST"

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let savePieceRequest = State.sendInputPosition
        ? SavePieceRequest(row: State.rowCoordinate, col: State.colCoordinate, dir: 0, flip: flip)
        : SavePieceRequest(row: nil, col: nil, dir: nil, flip: flip)
    request.httpBody = try? JSONEncoder().encode(savePieceRequest)
    request.httpShouldHandleCookies = false

    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: request) { (data, response, error) in
        guard let json = data else {
            print(error ?? "error when calling server")
            return
        }
        guard let savePieceResponse = try? JSONDecoder().decode(SavePieceResponse.self, from: json) else {
            print("failed to deserialize server response")
            return
        }
        State.suggestions = savePieceResponse.suggestions
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
