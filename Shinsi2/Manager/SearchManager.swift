
import UIKit

public extension Notification.Name {
    static let searchHistoryUpdate = Notification.Name("addSearchText")
}

class SearchManager: NSObject {

    static let shared = SearchManager()
    
    var _searchList: [[String: Any]]?
    var searchList: [[String: Any]] {
        get {
            if _searchList == nil {
                _searchList = UserDefaults.standard.value(forKey: "SearchList") as? [[String: Any]]
            }
            if _searchList == nil {
                _searchList = []
            }
            return _searchList!
        }
    }
    
    func addSearch(text: String?) {
        if nil != text {
            let _ = self.searchList
            _searchList?.insert(["text": text!, "date": Date()], at: 0)
            UserDefaults.standard.setValue(_searchList, forKey: "SearchList")
            NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
        }
    }
    
    func deleteSearch(index: Int) {
        _searchList?.remove(at: index)
        UserDefaults.standard.setValue(_searchList, forKey: "SearchList")
        NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
    }
    
}
