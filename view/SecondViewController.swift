//
//  SecondViewController.swift
//  view
//
//  Created by Kevin Chen on 8/17/18.
//  Copyright © 2018 Kevin Chen. All rights reserved.
//

import AVFoundation
import UIKit

class SecondViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let data = State.parsedImageData else {
            print("Error: no image data loaded")
            return
        }
        imageView.image = UIImage(data: data)
    }

    @IBAction func back(_ sender: Any) {
        print("back to start screen")
        dismiss(animated: true, completion: {})
    }
}
