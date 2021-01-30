import UIKit

class BaseNavigationController: UINavigationController {
    
    override var shouldAutorotate: Bool {
        return Defaults.GeneralSetting.isAutorotate
    }

}
