import UIKit

class SearchHistoryVC: UITableViewController {
    weak var searchController: UISearchController!
    var selectBlock: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateNotification(notification:)), name: .searchHistoryUpdate, object: nil)
        
        let blurview = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        tableView.backgroundView = blurview
    }
    
    @objc func handleUpdateNotification(notification: Notification) {
        self.tableView.reloadData()
    }
    
    @IBAction private func shortcutButtonDidClick(sender: UIButton) {
        selectBlock?(sender.titleLabel?.text ?? "")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchManager.shared.searchList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let r = SearchManager.shared.searchList[indexPath.row]
        cell.textLabel?.text = r["text"] as? String
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectBlock?(SearchManager.shared.searchList[indexPath.row]["text"] as! String)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            SearchManager.shared.deleteSearch(index: indexPath.row)
        }
    }
}
