//
//  PrivacyViewController.swift
//  wallet
//
//  Created by Chris Downie on 2/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import WebKit

class PrivacyViewController: UIViewController {
    var webView : WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        title = Localizations.PrivacyPolicy
        
        let locale = NSLocale.current.languageCode
        var privacyURL: URL
        
        switch locale {
        case "es":
            privacyURL = URL(string: "https://certifico.io/es/mobile-privacy")!
        case "mt":
            privacyURL = URL(string: "https://certifico.io/mt/mobile-privacy")!
        case "it":
            privacyURL = URL(string: "https://certifico.io/it/mobile-privacy")!
        case "ja":
            privacyURL = URL(string: "https://certifico.io/ja/mobile-privacy")!
        default:
            privacyURL = URL(string: "https://certifico.io/mobile-privacy")!
        }
        
        let request = URLRequest(url: privacyURL)
        webView.load(request)
    }

}


class AboutPassphraseViewController: UIViewController {
    var webView : WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        title = Localizations.AboutPassphrases
        
        let locale = NSLocale.current.languageCode
        var url: URL
        
        switch locale {
        case "es":
            url = URL(string: "https://certifico.io/es/about-passphrase")!
        case "mt":
            url = URL(string: "https://certifico.io/mt/about-passphrase")!
        case "it":
            url = URL(string: "https://certifico.io/it/about-passphrase")!
        case "ja":
            url = URL(string: "https://certifico.io/ja/about-passphrase")!
        default:
            url = URL(string: "https://certifico.io/about-passphrase")!
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
}
