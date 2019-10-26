//
//  PhotoDetailViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/10/22.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import FirebaseFirestore
import FirebaseStorage
import FirebaseUI
import FontAwesome_swift
import DynamicColor
import ImageScrollView

enum reason : String{
    case spam = "spam"
    case notContent = "notContent"
    
    func getTitle() -> String {
        switch self {
        case .spam:
            return LocalizeKey.spam.localizedString()
        case .notContent:
            return LocalizeKey.notContent.localizedString()
        }
    }
}

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: ImageScrollView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    var rPhoto: RealmPhoto?
    var fPhoto: OFirePhoto?
    
    private var fireReportCollection : CollectionReference = RootStore.rootDB().collection("report")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.setup()
        scrollView.imageScrollViewDelegate = self
        scrollView.imageContentMode = .aspectFit
        scrollView.initialOffset = .center
        
        if let rPhoto = rPhoto {
            scrollView.display(image: rPhoto.image!)
        } else if let fPhoto = fPhoto {
            let storageref = Storage.storage().reference(forURL: fPhoto.imageUrl)
            //            contentImageView = UIImageView(image: nil)
            storageref.getData(maxSize: 1 * 512 * 512) { (data, error) in
                if let data = data {
                    self.scrollView.display(image: UIImage(data: data)!)
                }
            }
        }
        
        closeButton.tintColor = .white
        closeButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 24, style: .solid)
        closeButton.setTitle(String.fontAwesomeIcon(name: .times), for: .normal)
        otherButton.tintColor = .white
        otherButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 24, style: .solid)
        otherButton.setTitle(String.fontAwesomeIcon(name: .ellipsisH), for: .normal)
        otherButton.titleLabel?.shadowColor = .black
        otherButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        closeButton.titleLabel?.shadowColor = .black
        closeButton.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        
        self.view.backgroundColor = UIColor.bgDark().lighter(amount: 0.1)
        bgView.backgroundColor = UIColor.clear
        captionLabel.textColor = .white
        captionLabel.sizeToFit()
        captionLabel.shadowColor = .black
        captionLabel.shadowOffset = CGSize(width: 1, height: 1)
        if let rPhoto = rPhoto {
            captionLabel.text = rPhoto.text
        } else if let fPhoto = fPhoto {
            captionLabel.text = fPhoto.title
        }
    }
    
    @IBAction func tapCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapOtherButton(_ sender: Any) {
        showOtherSheat()
    }
    
    func showOtherSheat() {
        let sheat = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: LocalizeKey.reportContent.localizedString(), style: .default) { (action) in
            self.showReportSheat()
        }
        let cancelAction = UIAlertAction(title: LocalizeKey.cancel.localizedString(), style: .cancel) { (action) in
        }
        sheat.addAction(reportAction)
        sheat.addAction(cancelAction)
        self.present(sheat, animated: true, completion: nil)
    }
    
    func showReportSheat() {
        let sheat = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let spamAction = UIAlertAction(title: reason.spam.getTitle(), style: .destructive) { (action) in
            self.sendReport(reason: reason.spam.rawValue)
        }
        let notContentAction = UIAlertAction(title: reason.notContent.getTitle(), style: .destructive) { (action) in
            self.sendReport(reason: reason.notContent.rawValue)
        }
        let cancelAction = UIAlertAction(title: LocalizeKey.cancel.localizedString(), style: .cancel) { (action) in
        }
        sheat.addAction(spamAction)
        sheat.addAction(notContentAction)
        sheat.addAction(cancelAction)
        self.present(sheat, animated: true, completion: nil)
    }
    
    func sendReport(reason: String) {
        let originID = UUID().uuidString
        let userId = GroupeDefaults.shared.authUid()
        let contentId: String!
        let ownerId: String!
        let imageUrl: String?
        if let fPhoto = fPhoto {
            contentId = fPhoto.id
            ownerId = fPhoto.ownerId
            imageUrl = fPhoto.imageUrl
        } else if let rPhoto = rPhoto {
            contentId = rPhoto.id
            ownerId = rPhoto.ownerId
            imageUrl = nil
        } else {
            contentId = "unknown"
            ownerId = "unknown"
            imageUrl = nil
        }
        let newReport = FireReport(userId: userId, ownerId: ownerId, contentId: contentId, reason: reason, imageUrl: imageUrl)
        let encoder = Firestore.Encoder()
        let newReportDoc = try! encoder.encode(newReport)
        self.fireReportCollection.document(originID).setData(newReportDoc, completion: { (error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("success save firestore", originID)
            }
        })
    }
}

extension PhotoDetailViewController: ImageScrollViewDelegate {
    func imageScrollViewDidChangeOrientation(imageScrollView: ImageScrollView) {
        print("Did change orientation")
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        print("scrollViewDidEndZooming at scale \(scale)")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollViewDidScroll at offset \(scrollView.contentOffset)")
    }
}
