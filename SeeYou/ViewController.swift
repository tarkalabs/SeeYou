//
//  ViewController.swift
//  SeeYou
//
//  Created by Vagmi Mudumbai on 02/11/16.
//  Copyright © 2016 Vagmi Mudumbai. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var btnPickScene: UIButton!
  var imgPicker:UIImagePickerController!
  var scenePicker:UIImagePickerController!
  
  @IBAction func pickSceneTouched(_ sender: AnyObject) {
    
    scenePicker.delegate = self
    scenePicker.allowsEditing = true
    scenePicker.sourceType = .camera
    present(scenePicker, animated: false, completion: nil)
  }
  @IBAction func pickImageTouched(_ sender: AnyObject) {
    
    imgPicker.delegate = self
    imgPicker.allowsEditing = true
    imgPicker.sourceType = .camera
    Comparor.instance.sourceImage = nil
    Comparor.instance.sourcePicked = false
    self.present(imgPicker, animated: false, completion: nil)
  }
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var lblVersion: UILabel!
  override func viewDidLoad() {
    super.viewDidLoad()
    btnPickScene.isEnabled = false
    imgPicker = UIImagePickerController()
    scenePicker = UIImagePickerController()
//    lblVersion.text = OpenCVWrapper.openCVVersionString()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if(!Comparor.instance.sourcePicked) {
      if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
        btnPickScene.isEnabled = true
//        self.imageView.image = OpenCVWrapper.processImage(image)
        self.imageView.image = image
        Comparor.instance.sourcePicked = true
      }
    } else {
      if let image = info[UIImagePickerControllerEditedImage] as? UIImage,
             let sImage = imageView.image {
        self.imageView.image = OpenCVWrapper.match(sImage, withScene: image)
      }
    }
    picker.dismiss(animated: false, completion: nil)
    
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: false, completion: nil)
  }
  
}

