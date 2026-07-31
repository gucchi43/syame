//
//  PhotoDetailViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/10/22.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import DynamicColor

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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    private var zoomImageView: UIImageView!
    var rPhoto: RealmPhoto?
    var fPhoto: OFirePhoto?
    var savedFlag: Bool = false

    private let supabase = SupabaseManager.shared
    private var imageTask: URLSessionDataTask?

    deinit {
        imageTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        zoomImageView = UIImageView()
        zoomImageView.contentMode = .scaleAspectFit
        zoomImageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(zoomImageView)
        NSLayoutConstraint.activate([
            zoomImageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            zoomImageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            zoomImageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            zoomImageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            zoomImageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            zoomImageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        if let rPhoto = rPhoto {
            zoomImageView.image = rPhoto.image
        } else if let fPhoto = fPhoto {
            if let url = URL(string: fPhoto.imageUrl) {
                imageTask = RemoteImageLoader.shared.load(url: url) { [weak self] image in
                    self?.zoomImageView.image = image
                }
            }
        }
        
        closeButton.tintColor = UIColor.acGreen()
        closeButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 24, style: .solid)
        closeButton.setTitle(String.fontAwesomeIcon(name: .times), for: .normal)
        otherButton.tintColor = UIColor.acGreen()
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
            if self.savedFlag {
                self.showUnSaveAlert()
            } else {
                self.showReportSheat()
            }
        }
        let blockContentAction = UIAlertAction(title: LocalizeKey.blockContent.localizedString(), style: .default) { (action) in
            if self.savedFlag {
                self.showUnSaveAlert()
            } else {
                self.showBlockAlert()
            }
        }
        let cancelAction = UIAlertAction(title: LocalizeKey.cancel.localizedString(), style: .cancel) { (action) in
        }
        sheat.addAction(reportAction)
        sheat.addAction(blockContentAction)
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
    
    func showBlockAlert() {
        let sheat = UIAlertController(title: LocalizeKey.blockContent.localizedString(), message: LocalizeKey.blockMessage.localizedString(), preferredStyle: .alert)

        let okAction = UIAlertAction(title: LocalizeKey.blockOK.localizedString(), style: .destructive) { (action) in
            self.blockPhoto()
        }
        let cancelAction = UIAlertAction(title: LocalizeKey.blockCancel.localizedString(), style: .cancel) { (action) in
        }
        sheat.addAction(okAction)
        sheat.addAction(cancelAction)
        self.present(sheat, animated: true, completion: nil)
    }
    
    func showUnSaveAlert() {
        let sheat = UIAlertController(title: LocalizeKey.butSavedContent.localizedString(), message: nil, preferredStyle: .alert)

        let okAction = UIAlertAction(title: LocalizeKey.butSavedOK.localizedString(), style: .default) { (action) in
            return
        }
        sheat.addAction(okAction)
        self.present(sheat, animated: true, completion: nil)
    }
    
    func blockPhoto() {
        var id: String?
        if let fPhoto = fPhoto {
            id = fPhoto.id.uuidString
        } else if let rPhoto = rPhoto {
            id = rPhoto.id
        } else {
            id = nil
        }
        guard let blockId = id else { return }
        GroupeDefaults.shared.addBlockContents(id: blockId)
        self.dismiss(animated: true, completion: nil)
    }

    func sendReport(reason: String) {
        let contentId: UUID?
        let ownerId: String
        let imageUrl: String?
        if let fPhoto = fPhoto {
            contentId = fPhoto.id
            ownerId = fPhoto.ownerId?.uuidString ?? "unknown"
            imageUrl = fPhoto.imageUrl
        } else if let rPhoto = rPhoto {
            contentId = UUID(uuidString: rPhoto.id)
            ownerId = rPhoto.ownerId
            imageUrl = nil
        } else {
            contentId = nil
            ownerId = "unknown"
            imageUrl = nil
        }

        Task { [weak self] in
            guard let self = self else { return }
            do {
                // 未認証のままだと user_id が nil になり RLS を通らず通報が黙って捨てられる
                let userId = try await SupabaseManager.shared.ensureSignedIn()
                let report = Report(
                    userId: userId,
                    ownerId: ownerId,
                    contentId: contentId,
                    reason: reason,
                    imageUrl: imageUrl
                )
                try await self.supabase.client.from("reports").insert(report).execute()
                // 送信できたときだけブロックして閉じる
                self.blockPhoto()
            } catch {
                self.showReportError(error)
            }
        }
    }

    private func showReportError(_ error: Error) {
        let alert = UIAlertController(title: nil,
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.baseOK.localizedString(), style: .default))
        present(alert, animated: true)
    }
}

extension PhotoDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImageView
    }
}
