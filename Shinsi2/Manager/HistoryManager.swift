
import UIKit

class HistoryManager: NSObject {

    static let shared = HistoryManager()
    
    override init() {
        super.init()
        if let decoded = UserDefaults.standard.object(forKey: "HistoryList") as? NSData {
            historyList = NSKeyedUnarchiver.unarchiveObject(with: decoded as Data) as! [GalleryModel]
        }
    }
    
    var historyList: [GalleryModel] = []
    
    func addHistory(galleryModel: GalleryModel?) {
        if nil != galleryModel {
            if let index = historyList.firstIndex(where: { return $0.gid == galleryModel!.gid}) {
                historyList.remove(at: index)
            }
            historyList.insert(galleryModel!, at: 0)
            do {
                let encodedData = try NSKeyedArchiver.archivedData(withRootObject: historyList, requiringSecureCoding: false)
                UserDefaults.standard.set(encodedData, forKey: "HistoryList")
            } catch  {
                print(error)
            }
        }
    }

}
