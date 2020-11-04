
import UIKit

public extension Notification.Name {
    static let searchHistoryUpdate = Notification.Name("addSearchText")
}

class SearchManager: NSObject {

    static let shared = SearchManager()
    
    override init() {
        super.init()
        if let searchList = UserDefaults.standard.value(forKey: "SearchList") as? [[String: Any]] {
            self.searchList = searchList
        }
    }
    
    var searchList: [[String: Any]] = []
    
    func addSearch(text: String?) {
        if nil != text && !text!.isEmpty {
            if let index = searchList.firstIndex(where: { return $0["text"] as! String == text!}) {
                searchList.remove(at: index)
            }
            searchList.insert(["text": text!, "date": Date()], at: 0)
            
            if searchList.count > 100 {
                self.searchList = Array(self.searchList[0...100])
            }
            
            UserDefaults.standard.setValue(searchList, forKey: "SearchList")
            NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
        }
    }
    
    func deleteSearch(index: Int) {
        searchList.remove(at: index)
        UserDefaults.standard.setValue(searchList, forKey: "SearchList")
        NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
    }
    
}
