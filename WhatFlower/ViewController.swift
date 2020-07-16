//
//  ViewController.swift
//  WhatFlower
//
//  Created by Allan on 16/07/20.
//  Copyright © 2020 Allan Galdino. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var label: UILabel!
  
  let wikipediaURl = "https://en.wikipedia.org/w/api.php"
  let imagePicker = UIImagePickerController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imagePicker.delegate = self
    imagePicker.sourceType = .camera
    imagePicker.allowsEditing = true
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
    if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
      guard let convertedCIImage = CIImage(image: userPickedImage) else {
        fatalError("Could not convert UIImage to a CIImage")
      }
      
      detect(image: convertedCIImage)
    }
    
    imagePicker.dismiss(animated: true, completion: nil)
  }
  
  func detect(image: CIImage){
    guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
      fatalError("Loading CoreML Model failed")
    }
    
    let request = VNCoreMLRequest(model: model) { (request, error) in
      guard let classification = request.results?.first as? VNClassificationObservation else {
        fatalError("Could not classify image.")
      }
      
      let flowerName = classification.identifier
      
      self.navigationItem.title = flowerName.capitalized
      
      self.requestInfo(flowerName: flowerName)
      
    }
    
    let handler = VNImageRequestHandler(ciImage: image)
    
    do {
      try handler.perform([request])
    } catch {
      print(error)
    }
  }
  
  func requestInfo(flowerName: String) {
    
    let parameters : [String:String] = [
      "format" : "json",
      "action" : "query",
      "prop" : "extracts|pageimages",
      "exintro" : "",
      "explaintext" : "",
      "titles" : flowerName,
      "indexpageids": "",
      "redirects" : "1",
      "pithumbsize": "500"
    ]

    
    Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
      if response.result.isSuccess {
        print("Got the wikipedia info.")
        
        let flowerJSON : JSON = JSON(response.result.value!)
        let pageID = flowerJSON["query"]["pageids"][0].stringValue
        let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
        let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
        
        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
        self.label.text = flowerDescription
      }
    }
  }
  
  @IBAction func cameraButtonPressed(_ sender: Any) {
    present(imagePicker, animated: true, completion: nil)
  }
  
}

