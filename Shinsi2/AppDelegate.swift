import UIKit

import SVProgressHUD
import KSCrash

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setDefaultAppearance()
        setDefaultHudAppearance()
        setCrashReport()
        
        Defaults.Search.categories.map { [$0: true] }.forEach { UserDefaults.standard.register(defaults: $0) }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        guard Defaults.GeneralSetting.isUseBiometrics else {
            return
        }
        BiometricsManager.isLock = true
        window?.isHidden = true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        guard Defaults.GeneralSetting.isUseBiometrics else {
            window?.makeKeyAndVisible()
            return
        }
        if BiometricsManager.isLock {
            BiometricsManager.refresh()
        }
        window?.isHidden = true
        BiometricsManager.authenticate(for: "Please unlock~") { (success) in
            if success {
                self.window?.isHidden = false
                BiometricsManager.isLock = false
            }
        }
    }
    
    func setDefaultAppearance() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
        UINavigationBar.appearance().tintColor = kMainColor
        UINavigationBar.appearance().barStyle = .blackTranslucent
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = #colorLiteral(red: 0.09966118171, green: 0.5230001833, blue: 0.8766457805, alpha: 1)
    }
    
    func setDefaultHudAppearance() {
        SVProgressHUD.setCornerRadius(10)
        SVProgressHUD.setMinimumSize(CGSize(width: 120, height: 120))
        SVProgressHUD.setForegroundColor(window?.tintColor ?? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMinimumDismissTimeInterval(3)
        SVProgressHUD.setImageViewSize(CGSize(width: 44, height: 44))
    }
    
    func setCrashReport() {
        let installation = KSCrashInstallationEmail.sharedInstance()
        installation?.recipients = ["tokinogaki@gmail.com"]
        installation?.setReportStyle(KSCrashEmailReportStyleApple, useDefaultFilenameFormat: true)
        installation?.addConditionalAlert(withTitle: "Crash Detected", message: "The app crashed last time it was launched. Send a crash report?", yesAnswer: "Sure!", noAnswer: "No thanks")
        installation?.install()
        
        installation?.sendAllReports(completion: { (reports, completed, error) in
            if error != nil {
                print("Sent \(String(describing: reports?.count)) reports")
            }
            else {
                print("Failed to send reports: \(error)")
            }
        })
    }
}
