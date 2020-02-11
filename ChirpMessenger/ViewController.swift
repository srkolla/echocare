/*------------------------------------------------------------------------------
 *
 *  ViewController.swift
 *
 *  For full information on usage and licensing, see https://chirp.io/
 *
 *  Copyright © 2011-2019, Asio Ltd.
 *  All rights reserved.
 *
 *----------------------------------------------------------------------------*/

import UIKit
import AVFoundation


class ViewController: UIViewController, UITextViewDelegate {

    let chirpGrey: UIColor = UIColor(red: 84.0 / 255.0, green: 84.0 / 255.0, blue: 84.0 / 255.0, alpha: 1.0)
    let chirpBlue: UIColor = UIColor(red: 43.0 / 255.0, green: 74.0 / 255.0, blue: 201.0 / 255.0, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Listen for app going to the background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Minimise keyboard when touching outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)

        // Add padding to textViews
        self.inputText.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        self.receivedText.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)

        // Set up some colours for buttons
        self.sendButton.setTitleColor(UIColor.white, for: .disabled)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let sdk = appDelegate.sdk {

            print(sdk.version);

            sdk.sendingBlock = {
                (data : Data?, channel: UInt?) -> () in
                self.configureSendButton(enabled: false, title: "SENDING", colour: self.chirpGrey)
                return;
            }

            sdk.sentBlock = {
                (data : Data?, channel: UInt?) -> () in
                self.configureSendButton(enabled: true, title: "SEND", colour: self.chirpBlue)
                return;
            }

            sdk.receivingBlock = {
                (channel: UInt?) -> () in
                self.configureSendButton(enabled: false, title: "RECEIVING", colour: self.chirpGrey)
                self.receivedText.text = "...."
                return;
            }

            sdk.receivedBlock = {
                (data : Data?, channel: UInt?) -> () in
                self.configureSendButton(enabled: true, title: "SEND", colour: self.chirpBlue)
                if let data = data {
                    if let payload = String(data: data, encoding: .utf8) {
                        self.receivedText.text = payload
                        print(String(format: "Received: %@", payload))
                    } else {
                        print("Failed to decode payload!")
                    }
                } else {
                    print("Decode failed!")
                }
                return;
            }
        }
    }

    /*
     * Ensure buttons are not left disabled when
     * returning from the background.
     */
    @objc func appMovedToBackground() {
        self.configureSendButton(enabled: true, title: "SEND", colour: self.chirpBlue)
        self.receivedText.text = "Received message"
    }

    /*
     * Configure the send buttons properties
     */
    func configureSendButton(enabled: Bool, title: String, colour: UIColor) {
        self.sendButton.isEnabled = enabled
        self.sendButton.setTitle(title, for: .normal)
        self.sendButton.backgroundColor = colour
    }

    /*
     * Convert inputText to NSData and send to the speakers.
     * Check volume is turned up enough before doing so.
     */
    func sendInput() {
        if AVAudioSession.sharedInstance().outputVolume < 0.1 {
            let errmsg = "Please turn the volume up to send messages"
            let alert = UIAlertController(title: "Alert", message: errmsg, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let sdk = appDelegate.sdk {
                let data = self.inputText.text.data(using: .utf8)
                if let data = data {
                    if let error = sdk.send(data) {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }

    /*
     * Clear the inputText on click.
     */
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.inputText.text == "Enter message..." {
            self.inputText.text = ""
        }
    }

    @IBAction func send(_ sender: Any) {
        self.minimiseKeyboard()
        self.sendInput()
    }

    /*
     * Check the length of the data does not exceed
     * the max payload length.
     * Catch any return keys in the inputText view
     * and close the keyboard.
     */
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        let data = self.inputText.text.data(using: .utf8)
    
        if let data = data {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let sdk = appDelegate.sdk {
                if data.count >= sdk.maxPayloadLength, text != "" {
                //if data.count >= 50, text != "" {
                    return false
                }
            }
        }
        return true
    }
    
    /*
     * Minimise keyboard.
     */
    func minimiseKeyboard() {
        self.inputText.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        self.minimiseKeyboard()
    }

    @IBOutlet var sendButton: UIButton!
    @IBOutlet var inputText: UITextView!
    @IBOutlet var receivedText: UITextView!
}

