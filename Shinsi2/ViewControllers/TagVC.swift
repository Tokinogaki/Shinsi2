import UIKit
import Hero
import AloeStackView

class TagVC: BaseViewController {
    weak var galleryPage: GalleryPage!
    var clickBlock: ((String) -> Void)?
    let stackView = AloeStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor(white: 0, alpha: 0.5)
        
        view.addSubview(stackView)
        stackView.frame = view.bounds
        stackView.separatorInset = .zero
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        for item in self.galleryPage.tags {
            stackView.addRow(createTitleLable(text: item.name))
            for tag in item.values {
                let l = createTextLable(text: tag)
                l.isUserInteractionEnabled = true
                stackView.addRow(l)
                stackView.hideSeparator(forRow: l)
                stackView.setInset(forRow: l, inset: UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15))
                stackView.setTapHandler(forRow: l) { [weak self] _ in
                    let string = item.name == "misc" ? tag : item.name + ":" + tag
                    self?.clickBlock?(string)
                }
            }
        }
    }
    
    func createTitleLable(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.darkGray
        return label
    }
    
    func createTextLable(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        return label
    }
}
