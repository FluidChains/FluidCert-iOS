//
//  AddCredentialViewController.swift
//  certificates
//
//  Created by Michael Shin on 8/30/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

class AddCredentialViewController: UIViewController, UIDocumentPickerDelegate {
    
    var alert: AlertViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Add a Credential", comment: "Title in settings")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.instance.styleApplicationDefault()
    }
    
    // MARK: - Add Credential
    
    @IBAction func importFromURL() {
        Logger.main.info("Add Credential from URL tapped in settings")
        let storyboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "addCredentialFromURL") as! AddCredentialURLViewController
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func importFromFile() {
        Logger.main.info("User has chosen to add a certificate from file")
        
        let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        controller.delegate = self
        controller.modalPresentationStyle = .formSheet
        
        AppDelegate.instance.styleApplicationAlternate()
        present(controller, animated: true, completion: nil)
    }
    
    func importCertificate(from data: Data?) {
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        alert = AlertViewController.createProgress(title: NSLocalizedString("Adding Credential", comment: "Title when adding issuer in progress"))
        present(alert!, animated: false, completion: nil)
        
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                self?.alertAppUpdate()
                return
            }
            
            guard let data = data else {
                Logger.main.error("Failed to load a certificate from file. Data is nil.")
                
                let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
                let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")
                self?.alertError(title: title, message: message)
                return
            }
            
            do {
                let certificate = try CertificateParser.parse(data: data)
                self?.saveCertificateIfOwned(certificate: certificate)
                
                self?.alertSuccess(callback: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            } catch {
                Logger.main.error("Importing failed with error: \(error)")
                
                let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
                let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")
                self?.alertError(title: title, message: message)
                return
            }
        }
    }
    
    func saveCertificateIfOwned(certificate: Certificate) {
        guard !userCancelledAction else { return }
        let manager = CertificateManager()
        manager.save(certificate: certificate)
    }
    
    var userCancelledAction = false
    
    // User tapped cancel in progress alert
    func cancelAddCredential() {
        userCancelledAction = true
    }
    
    func alertError(title: String, message: String) {
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: title)
        alert.set(message: message)
        alert.icon = .warning
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "OK dismiss action"), for: .normal)
        okayButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton])
    }
    
    func alertSuccess(callback: (() -> Void)?) {
        guard let alert = alert else { return }
        
        let title = NSLocalizedString("Success!", comment: "Alert title")
        let message = NSLocalizedString("A credential was imported. Please check your credentials screen.", comment: "Successful credential import from URL in settings alert message")
        
        alert.type = .normal
        alert.set(title: title)
        alert.set(message: message)
        alert.icon = .success
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "OK dismiss action"), for: .normal)
        okayButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: {
                callback?()
            })
        }
        alert.set(buttons: [okayButton])
    }
    
    func alertAppUpdate() {
        Logger.main.info("App needs update.")
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: NSLocalizedString("[Old Version]", comment: "Force app update dialog title"))
        alert.set(message: NSLocalizedString("[Lorem ipsum latin for go to App Store]", comment: "Force app update dialog message"))
        alert.icon = .warning
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "Button copy"), for: .normal)
        okayButton.onTouchUpInside {
            let url = URL(string: "itms://itunes.apple.com/us/app/blockcerts-wallet/id1146921514")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            alert.dismiss(animated: false, completion: nil)
        }
        
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Dismiss action"), for: .normal)
        cancelButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        
        alert.set(buttons: [okayButton, cancelButton])
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try? Data(contentsOf: url)
        importCertificate(from: data)
    }
    
}

class AddCredentialURLViewController: AddCredentialViewController, UITextViewDelegate {
    
    @IBOutlet weak var urlTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    // closure called when presented modally and credential successfully added
    var successCallback: ((Certificate) -> ())?
    var presentedModally = false
    
    @IBAction func importURL() {
        guard let urlString = urlTextView.text,
            let url = URL(string: urlString.trimmingCharacters(in: CharacterSet.whitespaces)) else {
                return
        }
        
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        alert = AlertViewController.createProgress(title: NSLocalizedString("Adding Credential", comment: "Title when adding issuer in progress"))
        present(alert!, animated: false, completion: nil)
        
        Logger.main.info("User attempting to add a certificate from \(url).")
        
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                self?.alertAppUpdate()
                return
            }
            
            self?.addCertificate(from: url)
        }
    }
    
    func addCertificate(from url: URL) {
        urlTextView.resignFirstResponder()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let certificate = CertificateManager().load(certificateAt: url) else {
                DispatchQueue.main.async { [weak self] in
                    Logger.main.error("Failed to load certificate from \(url)")
                    
                    let title = NSLocalizedString("Invalid Credential", comment: "Title for an alert when importing an invalid certificate")
                    let message = NSLocalizedString("That file doesn't appear to be a valid credential.", comment: "Message in an alert when importing an invalid certificate")
                    self?.alertError(title: title, message: message)
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard !(self?.userCancelledAction ?? false) else { return }
                self?.saveCertificateIfOwned(certificate: certificate)
                
                self?.alertSuccess(callback: { [weak self] in
                    if self?.presentedModally ?? true {
                        self?.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                            self?.successCallback?(certificate)
                        })
                    } else {
                        self?.navigationController?.popViewController(animated: true)
                    }
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextView.backgroundColor = Style.Color.C10
        urlTextView.text = ""
        urlTextView.delegate = self
        urlTextView.font = Style.Font.T3S
        urlTextView.textColor = Style.Color.C3
        submitButton.isEnabled = false
    }
    
    @objc func dismissModally() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // Mark: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        submitButton.isEnabled = textView.text.count > 0
    }
    
}
