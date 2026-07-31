//
//  AddViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import SwiftDate
import TagListView
import DynamicColor

class AddViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var publicLabel: UILabel!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var genreListView: TagListView!
    
    @IBOutlet weak var publicSwitch: UISwitch!
    var choiceImage: UIImage! //選択された元画像
    var selectedJenreTag: GenreTagType?
    
    var publicFlag = true
    
    private let supabase = SupabaseManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    func commonInit() {
        navigationItem.title = LocalizeKey.addNavTitle.localizedString()
        doneButton.setTitle(LocalizeKey.addDone.localizedString() , for: .normal)
        titleLabel.text = LocalizeKey.addInputTitle.localizedString()
        genreLabel.text = LocalizeKey.addInputGenre.localizedString()
        publicLabel.text = LocalizeKey.addPublicSwitchOn.localizedString()
        titleLabel.textColor = .white
        genreLabel.textColor = .white
        publicLabel.textColor = .white
        view.backgroundColor = .bgDark()
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),
                                 for: UIControl.Event.editingChanged)
        if let image = choiceImage {
            imageView.image = image
        }
        publicSwitch.tintColor = UIColor.acGreen()
        publicSwitch.onTintColor = UIColor.acGreen()
        closeButton.title = String.fontAwesomeIcon(name: .times)
        closeButton.setTitleTextAttributes([.font: UIFont.fontAwesome(ofSize: 24, style: .solid)], for: .normal)
        
        genreListView.delegate = self
        genreListView.backgroundColor = .clear
        genreListView.addTags(GenreTagType.getAddAllGenreTitles())
        genreListView.textFont = UIFont.systemFont(ofSize: 18)
        genreListView.shadowRadius = 2
        genreListView.shadowOpacity = 0.4
        genreListView.alignment = .left
        genreListView.marginX = 12
        genreListView.marginY = 6
        genreListView.paddingX = 12
        genreListView.paddingY = 6
        genreListView.shadowOffset = CGSize(width: 1, height: 1)
        genreListView.borderWidth = 2
        genreListView.shadowColor = .black
        genreListView.textColor = .acGreen()
        genreListView.borderColor = .acGreen()
        genreListView.tagBackgroundColor = .white
        addButtonState()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        addButtonState()
    }
    
    func addButtonState() {
        if !(titleTextField.text ?? "").isEmpty && choiceImage != nil && selectedJenreTag != nil {
            doneButton.isEnabled = true
            doneButton.backgroundColor = .acGreen()
            doneButton.setTitleColor(.white, for: .normal)
        } else {
            doneButton.isEnabled = false
            let acGreen = UIColor.acGreen()
            let acGreenDark = acGreen.darkened()
            doneButton.backgroundColor = acGreenDark
            doneButton.setTitleColor(.white, for: .normal)
        }
    }
    
    func setTagColor(tag: TagView) {
        genreListView.textColor = .acGreen()
        genreListView.borderColor = .acGreen()
        genreListView.tagBackgroundColor = .white
        
        if tag.isSelected {
            tag.textColor = .white
            tag.borderColor = .acGreen()
            tag.tagBackgroundColor = .acGreen()
        }
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if sender.isOn {
            publicLabel.text = LocalizeKey.addPublicSwitchOn.localizedString()
        } else {
            publicLabel.text = LocalizeKey.addPublicSwitchOff.localizedString()
        }
        publicFlag = sender.isOn
    }
    
    
    // 長い方の辺をmaxLengthに合わせる
    /// 投稿画像の長辺の上限。
    /// 300pxではキーボードのセル(画面半分 = 3x端末で約600px)にも足りず明確に粗く見えるため、
    /// 一般的なSNSと同程度の1080pxまで引き上げる。
    private static let maxImageLength: CGFloat = 1080

    // 長い方の辺をmaxLengthに合わせる
    func convertedImageSize(size: CGSize) -> CGSize{
        let longerSide = max(size.width, size.height)
        guard longerSide > 0 else { return size }
        // 元画像より大きくしても画質は上がらないので拡大はしない
        let ratio = min(AddViewController.maxImageLength / longerSide, 1.0)
        return CGSize(width: size.width * ratio, height: size.height * ratio)
    }
    
    @IBAction func tapCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

    private enum UploadError: LocalizedError {
        case invalidImage
        case realmSaveFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "画像を処理できませんでした"
            case .realmSaveFailed: return "端末への保存に失敗しました"
            }
        }
    }

    /// insert のペイロード。辞書で送ると数値・真偽値まで文字列になり暗黙キャストに依存してしまう。
    private struct PhotoInsert: Encodable {
        let id: String
        let title: String
        let image_height: Int
        let image_width: Int
        let image_url: String
        let genre: String
        let total_save_count: Int
        let weekly_save_count: Int
        // week_start_day はクライアントとサーバで書式が食い違うため送らない(DBの既定値に任せる)
        let owner_id: String
        let locale: String
        let is_debug: Bool
    }

    @IBAction func tapDoneButton(_ sender: Any) {
        // UIKitの値はメインスレッドで読み取ってからTaskに渡す
        guard let sourceImage = choiceImage,
              let postImage = sourceImage.resize(size: convertedImageSize(size: sourceImage.size)),
              let genre = selectedJenreTag else {
            return
        }
        let titleText = titleTextField.text ?? ""
        doneButton.isEnabled = false

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let id: String
                if self.publicFlag {
                    id = try await self.uploadToServer(title: titleText, genre: genre, postImage: postImage)
                } else {
                    // 非公開投稿はサーバに存在しないため端末内でIDを採番する
                    id = UUID().uuidString
                }
                guard self.saveRealm(id: id, title: titleText, postedImage: postImage, isPublic: self.publicFlag) else {
                    throw UploadError.realmSaveFailed
                }
                NotificationCenter.default.post(name: .finishUpload, object: nil, userInfo: nil)
                self.dismiss(animated: true, completion: nil)
            } catch {
                // 完了を待たずに閉じると失敗がユーザーに伝わらない
                self.doneButton.isEnabled = true
                self.showUploadError(error)
            }
        }
    }

    private func uploadToServer(title: String, genre: GenreTagType, postImage: UIImage) async throws -> String {
        // 認証完了前に投稿すると owner_id が空になり RLS を通らないため先に待つ
        let ownerId = try await SupabaseManager.shared.ensureSignedIn()
        guard let imageData = postImage.jpegData(compressionQuality: RealmPhoto.jpegCompressionQuality) else {
            throw UploadError.invalidImage
        }
        let originID = UUID()
        let filePath = "\(supabase.locale)/\(originID.uuidString).jpg"

        try await supabase.client.storage.from("photos")
            .upload(filePath, data: imageData, options: .init(contentType: "image/jpeg"))

        do {
            let publicURL = try supabase.client.storage.from("photos").getPublicURL(path: filePath)
            let payload = PhotoInsert(id: originID.uuidString,
                                      title: title,
                                      image_height: Int(postImage.size.height),
                                      image_width: Int(postImage.size.width),
                                      image_url: publicURL.absoluteString,
                                      genre: genre.getKey(),
                                      total_save_count: 1,
                                      weekly_save_count: 1,
                                      owner_id: ownerId.uuidString,
                                      locale: supabase.locale,
                                      is_debug: supabase.isDebug)
            try await supabase.client.from("photos").insert(payload).execute()
            return originID.uuidString
        } catch {
            // DB登録に失敗するとStorage上のファイルが孤児になるため取り消す
            _ = try? await supabase.client.storage.from("photos").remove(paths: [filePath])
            throw error
        }
    }

    @discardableResult
    private func saveRealm(id: String, title: String, postedImage: UIImage, isPublic: Bool) -> Bool {
        let new = RealmPhoto.create(id: id,
                                    text: title,
                                    image: postedImage,
                                    imageHeight: Int(postedImage.size.height),
                                    imageWidth: Int(postedImage.size.width),
                                    getDay: Date().toString(),
                                    isPublic: isPublic,
                                    ownerId: GroupeDefaults.shared.authUid())
        var saved = false
        RealmManager.shared.save(data: new, success: { saved = true }, failure: { _ in saved = false })
        return saved
    }

    private func showUploadError(_ error: Error) {
        let alert = UIAlertController(title: nil,
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.baseOK.localizedString(), style: .default))
        present(alert, animated: true)
    }
}

extension AddViewController: TagListViewDelegate {
    // MARK: TagListViewDelegate
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        print("Tag pressed: \(title), \(sender)")

        guard let newTag = GenreTagType.getTypeFromTitle(title: title) else {
            return
        }
        
        if selectedJenreTag == newTag {
            selectedJenreTag = nil
            tagView.isSelected = false
        } else if selectedJenreTag != nil {
            genreListView.selectedTags().first?.isSelected = false
            selectedJenreTag = newTag
            tagView.isSelected = true
        } else {
            selectedJenreTag = newTag
            tagView.isSelected = true
        }
        
        print("genreListView.selectedTags().count : ", genreListView.selectedTags().count)
        
        setTagColor(tag: tagView)
        addButtonState()
    }
    
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) {
        print("Tag Remove pressed: \(title), \(sender)")
        sender.removeTagView(tagView)
    }
}


extension AddViewController: UITextFieldDelegate {
    //テキストフィールドでリターンが押されたときに通知され起動するメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //textField.resignFirstResponder()　←↓どっちでもいい
        self.view.endEditing(true)
        return true
    }
}
