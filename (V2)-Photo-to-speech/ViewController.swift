//
//  ViewController.swift
//  (V2)-Photo-to-speech
//
//  Created by Brian Butchart on 2018-08-24.
//  Copyright © 2018 Brian Butchart. All rights reserved.
//

import UIKit
import AVFoundation
import SVProgressHUD
import TesseractOCR
//import AKImageCropperView

//global variables
var rate : Float = 0.5
var pitch : Float = 1.0
var languageCode = "en-US"

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVSpeechSynthesizerDelegate {
    
    //global variables
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "") 
    var textResult = ""
    var thresImage : UIImage? = nil

    @IBOutlet weak var imagePicked: UIImageView!
    
    //function that makes hiding media control buttons a bit easier
    func toggleButtons(playHidden: Bool, pauseHidden: Bool, stopHidden: Bool, restartHidden: Bool) {
        if playHidden == true {
            playButtonOutlet.isHidden = true
        } else {
            playButtonOutlet.isHidden = false
        }
        if pauseHidden == true {
            pauseButtonOutlet.isHidden = true
        } else {
            pauseButtonOutlet.isHidden = false
        }
        if stopHidden == true {
            stopButtonOutlet.isHidden = true
        } else {
            stopButtonOutlet.isHidden = false
        }
        if restartHidden == true {
            restartButtonOutlet.isHidden = true
        } else {
            restartButtonOutlet.isHidden = false
        }
    }
    
    //So I can stop the speech when you do the degue
    func showRestartButtonOnly() {
        toggleButtons(playHidden: true, pauseHidden: true, stopHidden: true, restartHidden: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        synth.delegate = self
        toggleButtons(playHidden: true, pauseHidden: true, stopHidden: true, restartHidden: true)
        
    }
    
    @IBAction func settingsButton(_ sender: UIButton) {
        
        performSegue(withIdentifier: "settingsSegue", sender: self)
        if synth.isSpeaking {
            showRestartButtonOnly()
            synth.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
    }

    
    //MARK: Camera setup
    @IBAction func openCameraButton(_ sender: UIButton) {
        //is camera available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            //delegete + camera settings stuff
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated : true, completion: nil)
        }
    }
    
    //MARK: Protocol
    //protocol thing, automatically called
    //this function takes the image, shows it in the imageview, scans the text, and reads it out loud
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // put it in a queue so the UI could update properly
            let queue = DispatchQueue(label: "SerialQueue")
            DispatchQueue.main.async(execute: {
                //starts Progress HUD
                SVProgressHUD.show(withStatus: "Thinking...")
                //displays picked image on UIImageView
                self.imagePicked.image = image
                self.smallImageView.image = image
                self.smallTextField.text = ""
                self.dismiss(animated: true, completion: nil)
                self.toggleButtons(playHidden: true, pauseHidden: true, stopHidden: true, restartHidden: true)
            });
            queue.async {
                //reads aloud image that is parsed from a scaled image - three functions in total
                self.textToSpeech(text: self.getOCRdata(image: image.scaleImage(640)!))
            }
            
        } else {
            print("error!!! no image!!!")
        }
    }
    
    
    //MARK: Text to Speech
    func textToSpeech(text : String) {
        let voice = AVSpeechSynthesisVoice(language: languageCode)
        textResult = text
        myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = rate
        myUtterance.pitchMultiplier = pitch
        myUtterance.voice = voice
        synth.speak(myUtterance)
    }
    //checks if speech started and shows the pause and stop buttons
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        imagePicked.image = thresImage
        smallImageView.image = thresImage
        smallTextField.text = textResult
        if switchButtonOutlet.isHidden == true {
            switchButtonOutlet.isHidden = false
        }
        
        toggleButtons(playHidden: true, pauseHidden: false, stopHidden: false, restartHidden: true)
    }
    //checks if speech stops and removes all buttons execpt the replay button
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        showRestartButtonOnly()
    }


    //MARK: Speech control buttons
    //play button - shows pause button and hides after it is pressed
    @IBAction func playButton(_ sender: UIButton) {
        pauseButtonOutlet.isHidden = false
        playButtonOutlet.isHidden = true
        //continues speech
        synth.continueSpeaking()
    }
    
    @IBOutlet weak var playButtonOutlet: UIButton!
    
    //pause button - shows play button and hides after it is pressed
    @IBAction func pauseButton(_ sender: UIButton) {
        pauseButtonOutlet.isHidden = true
        playButtonOutlet.isHidden = false
        //pauses speech
        synth.pauseSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    @IBOutlet weak var pauseButtonOutlet: UIButton!
    
    //stop button - removes all buttons execpt the replay button
    @IBAction func stopButton(_ sender: UIButton) {
        showRestartButtonOnly()
        //stops speech - different than pausing
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    @IBOutlet weak var stopButtonOutlet: UIButton!
    
    //restarts speech using text stored in global variable
    @IBAction func restartButton(_ sender: UIButton) {
        toggleButtons(playHidden: true, pauseHidden: false, stopHidden: false, restartHidden: true)
        textToSpeech(text: textResult)
    }
    
    @IBOutlet weak var restartButtonOutlet: UIButton!
    
    //MARK: view control
    
    @IBAction func switchButton(_ sender: Any) {
        imagePicked.isHidden = !(imagePicked.isHidden)
        smallImageView.isHidden = !(smallImageView.isHidden)
        smallTextField.isHidden = !(smallTextField.isHidden)
    }
    
    @IBOutlet weak var switchButtonOutlet: UIButton!
    
    @IBOutlet weak var smallImageView: UIImageView!
    
    @IBOutlet weak var smallTextField: UITextView!
    
    
    //MARK: OCR
    func getOCRdata(image: UIImage) -> String {
        //creates an english G8Tesseract object
        if let tesseract = G8Tesseract(language: "eng") {
            //uses most precise mode - other options are less precise but faster Cube only and Tesseract only
            tesseract.engineMode = .tesseractCubeCombined
            //notices page breaks
            tesseract.pageSegmentationMode = .auto
            //makes binary image
            tesseract.image = image.g8_blackAndWhite()
            tesseract.recognize()
            let foundText = tesseract.recognizedText
            //sends thresholdedImage to the UIImageView via a global variable
            thresImage = tesseract.thresholdedImage
            //dismisses Progress HUD
            SVProgressHUD.dismiss()
            if foundText == "" {
                if languageCode == "fr-FR" {
                    return "Aucun texte trouvé"
                } else {
                    return "No text found"
                }
            } else {
                return foundText!
            }
        }
        return "Error: OCR Engine Malfunction"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

//MARK: image scaling
//Scaling the image makes it easier on Tesseract - 640 is about right for maxDimension
extension UIImage {
    func scaleImage(_ maxDimension: CGFloat) -> UIImage? {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        
        if size.width > size.height {
            let scaleFactor = size.height / size.width
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            let scaleFactor = size.width / size.height
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}
