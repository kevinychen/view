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
    @IBOutlet weak var sendModeControl: UISegmentedControl!
    @IBOutlet weak var coordinatePickerView: UIPickerView!
    @IBOutlet weak var suggestedCoordinatesView: UILabel!
    @IBOutlet weak var flipSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        sendModeControl.selectedSegmentIndex = State.sendInputPosition ? 0 : 1
        coordinatePickerView.dataSource = self
        coordinatePickerView.delegate = self
        coordinatePickerView.selectRow(State.rowCoordinate, inComponent: 0, animated: false)
        coordinatePickerView.selectRow(State.colCoordinate, inComponent: 1, animated: false)
        suggestedCoordinatesView.isHidden = true

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

    @IBAction func setSendMode(_ sender: UISegmentedControl) {
        let sendInputPosition = sender.selectedSegmentIndex == 0;
        State.sendInputPosition = sendInputPosition
        coordinatePickerView.isHidden = !sendInputPosition
        suggestedCoordinatesView.isHidden = sendInputPosition
    }

    @IBAction func send(_ sender: Any) {
    }
}

extension SecondViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? Constants.NUM_ROWS : Constants.NUM_COLS
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (component == 0) {
            State.rowCoordinate = row
        } else {
            State.colCoordinate = row
        }
    }
}
