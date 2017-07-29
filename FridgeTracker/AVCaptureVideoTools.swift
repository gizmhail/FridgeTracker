//
//  AVCaptureVideoTools.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 28/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension AVCaptureVideoOrientation {
    init?(from orientation:UIInterfaceOrientation) {
        switch (orientation) {
        case .portrait:
            self = .portrait;
        case .portraitUpsideDown:
            self = .portraitUpsideDown;
        case .landscapeLeft:
            self = .landscapeLeft;
        case .landscapeRight:
            self = .landscapeRight;
        default:
            return nil
        }
    }
}
