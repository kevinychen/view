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
    // bytes of original JPG image
    static var imageData: Data?

    // bytes of processed JPG image (with jigsaw piece sides highlighted)
    static var parsedImageData: Data?

    // whether the client is sending input positions (instead of asking the server to guess)
    static var sendInputPosition: Bool = true

    static var rowCoordinate: Int = 0
    static var colCoordinate: Int = 0
}
