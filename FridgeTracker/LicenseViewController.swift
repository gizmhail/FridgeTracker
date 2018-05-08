//
//  LicenseViewController.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 29/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import UIKit

class LicenseViewController: UIViewController {
    @IBOutlet weak var webview: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = URL(string: "https://github.com/gizmhail/FridgeTracker/blob/master/LICENSE.md") {
            self.webview.loadRequest(URLRequest(url: url))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LicenseViewController:UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.activityIndicator.stopAnimating()
    }
}
