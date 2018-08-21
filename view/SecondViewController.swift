//
//  SecondViewController.swift
//  view
//
//  Created by Kevin Chen on 8/17/18.
//  Copyright © 2018 Kevin Chen. All rights reserved.
//

import AVFoundation
import UIKit

let COLORS = [UIColor.red, UIColor.yellow, UIColor.green, UIColor.blue]

class SecondViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sendModeControl: UISegmentedControl!
    @IBOutlet weak var coordinatePickerView: UIPickerView!
    @IBOutlet weak var suggestionsView: UITableView!
    @IBOutlet weak var flipSwitch: UISwitch!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        sendModeControl.selectedSegmentIndex = State.sendInputPosition ? 0 : 1
        coordinatePickerView.dataSource = self
        coordinatePickerView.delegate = self
        coordinatePickerView.selectRow(State.rowCoordinate, inComponent: 0, animated: false)
        coordinatePickerView.selectRow(State.colCoordinate, inComponent: 1, animated: false)
        coordinatePickerView.isHidden = false
        suggestionsView.dataSource = self
        suggestionsView.delegate = self
        suggestionsView.isHidden = true

        guard let data = State.imageData else {
            print("Error: no image data loaded")
            return
        }
        let image = UIImage(data: data)!
        guard let piece = State.piece else {
            print("no piece set")
            return
        }
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: CGPoint.zero)
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(1.0)
        for index in 0..<4 {
            context.setStrokeColor(COLORS[index].cgColor)
            for point in piece.sides[index].points {
                context.addEllipse(in: CGRect(x: point.x - 2, y: point.y, width: 5, height: 5))
                context.drawPath(using: .fillStroke)
            }
        }
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        imageView.image = annotatedImage
    }

    @IBAction func back(_ sender: Any) {
        print("back to start screen")
        dismiss(animated: true, completion: {})
    }

    @IBAction func setSendMode(_ sender: UISegmentedControl) {
        let sendInputPosition = sender.selectedSegmentIndex == 0;
        State.sendInputPosition = sendInputPosition
        coordinatePickerView.isHidden = !sendInputPosition
        suggestionsView.isHidden = sendInputPosition
    }

    @IBAction func send(_ sender: Any) {
        sendButton.isHidden = true
        activityIndicator.startAnimating()

        let flip = flipSwitch.isOn
        savePiece(flip: flip) {
            DispatchQueue.main.async {
                self.suggestionsView.reloadData()
                self.sendButton.isHidden = false
                self.activityIndicator.stopAnimating()
            }
        }
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

extension SecondViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return State.suggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestionCell", for: indexPath)
        cell.textLabel?.text = State.suggestions[indexPath.row].description
        return cell
    }
}
