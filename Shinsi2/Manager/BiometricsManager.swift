//
//  BiometricsManager.swift
//  Shinsi2
//
//  Created by Tokinogaki on 14/6/20.
//  Copyright © 2020 PowHu Yang. All rights reserved.
//

import UIKit
import LocalAuthentication

class BiometricsManager: NSObject {
    
    public static var isLock = true
    
    public static var context = LAContext()
    
    static func refresh() {
        self.context = LAContext()
    }
    
    static func canSupported() -> Bool {
        var error: NSError?
        if Defaults.Setting.isUsePasscode && context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return true
        }
        
        if error != nil {
            print("Authentication failed: \(String(describing: error?.code)) -> \(getErrorString(reason: error))")
        }
        
        return false
    }
    
    static func authenticate(for reason: String, completion: @escaping (Bool) -> Void) {
        guard canSupported() else { return }
        if Defaults.Setting.isUsePasscode {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { (success, err) in
                if success {
                    print("Authenticated with \(getBiometryType())")
                } else if err != nil {
                    print("Authentication failed: \(getErrorString(reason: err as NSError?))")
                }

                DispatchQueue.main.async {
                    completion(success && err == nil)
                }
            }
        } else {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, err) in
                if success {
                    print("Authenticated with \(getBiometryType())")
                } else if err != nil {
                    print("Authentication failed: \(getErrorString(reason: err as NSError?))")
                }

                DispatchQueue.main.async {
                    completion(success && err == nil)
                }
            }
        }
    }
    
    static func getErrorString(reason error: NSError!) -> String {
        switch LAError.Code(rawValue: error.code) {
        case .authenticationFailed:
            return "LAErrorAuthenticationFailed"
        case .userCancel:
            return "LAErrorUserCancel"
        case .userFallback:
            return "LAErrorUserFallback"
        case .systemCancel:
            return "LAErrorSystemCancel"
        case .passcodeNotSet:
            return "LAErrorPasscodeNotSet"
        case .touchIDNotAvailable:
            return "LAErrorTouchIDNotAvailable"
        case .touchIDNotEnrolled:
            return "LAErrorTouchIDNotEnrolled"
        case .touchIDLockout:
            return "LAErrorTouchIDLockout"
        default:
            return "RCTTouchIDUnknownError"
        }
    }
    
    static func getBiometryType() -> String {
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "None"
        default:
            return "None"
        }
    }
}
