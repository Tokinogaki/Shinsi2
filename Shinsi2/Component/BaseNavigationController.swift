import UIKit

class BaseNavigationController: UINavigationController {
    
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if Defaults.GeneralSetting.isAutorotate {
            return .all
        }
        return [.portrait, .portraitUpsideDown]
    }

}
