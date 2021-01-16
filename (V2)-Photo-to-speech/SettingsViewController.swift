//
//  SettingsViewController.swift
//  (V2)-Photo-to-speech
//
//  Created by Brian Butchart on 2018-08-29.
//  Copyright © 2018 Brian Butchart. All rights reserved.
//

import UIKit
import AVFoundation

class SettingsViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    //outlets
    @IBOutlet weak var languageSegmentedControl: UISegmentedControl!
    
    //@IBOutlet weak var testTextView: UITextView!
    @IBOutlet weak var testTextView: UITextField!
    
    @IBOutlet weak var rateSliderOutlet: UISlider!
    
    @IBOutlet weak var pitchSliderOutlet: UISlider!
    
    @IBOutlet weak var languageSegmentedControlOutlet: UISegmentedControl!
    
    @IBOutlet weak var voiceTestButtonOutlet: UIButton!
    
    @IBOutlet weak var voiceStopButtonOutlet: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        synth.delegate = self
        
        //sets up options based on previous inputs
        rateSliderOutlet.value = rate
        pitchSliderOutlet.value = pitch
        
        if languageCode == "en-US" {
            languageSegmentedControlOutlet.selectedSegmentIndex = 0
            languageSegmentedControlOutlet.sendActions(for: .valueChanged)
        } else if languageCode == "fr-FR" {
            languageSegmentedControlOutlet.selectedSegmentIndex = 1
            languageSegmentedControlOutlet.sendActions(for: .valueChanged)
        }
        

        // Do any additional setup after loading the view.
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    @IBAction func rateSlider(_ sender: UISlider) {
        rate = sender.value
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    @IBAction func pitchSlider(_ sender: UISlider) {
        pitch = sender.value
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    @IBAction func languageSegmentedControlIndexChanged(_ sender: UISegmentedControl) {
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
        switch languageSegmentedControl.selectedSegmentIndex {
        case 0:
            languageCode = "en-US"
            testTextView.text = "The quick brown fox jumps over a lazy dog"
        case 1:
            languageCode = "fr-FR"
            //french pangram!!
            testTextView.text = "Portez ce vieux whisky au juge blond qui fume"
        default:
            break
        }
    }
    //test voice while toggling different options
    @IBAction func voiceTestButton(_ sender: UIButton) {
        let voice = AVSpeechSynthesisVoice(language: languageCode)
        myUtterance = AVSpeechUtterance(string: testTextView.text!)
        myUtterance.rate = rate
        myUtterance.pitchMultiplier = pitch
        myUtterance.voice = voice
        synth.speak(myUtterance)
    }
    
    @IBAction func voiceStopButton(_ sender: UIButton) {
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        voiceTestButtonOutlet.isHidden = true
        voiceStopButtonOutlet.isHidden = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        voiceTestButtonOutlet.isHidden = false
        voiceStopButtonOutlet.isHidden = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        voiceTestButtonOutlet.isHidden = false
        voiceStopButtonOutlet.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
