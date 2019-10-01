//
//  AddViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import RealmSwift
import Realm
import PhotoKeyboardFramework
import SwiftDate
import TagListView
import FontAwesome_swift
import DynamicColor
import Firebase
import FirebaseFirestoreSwift

class AddViewController: UIViewController {

//    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
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
//    var postImage: UIImage!
    var selectedJenreTag: GenreTagType?
    
    var publicFlag = true
    
    private var firePhotoCollection : CollectionReference = RootStore.rootDB().collection("ofirephoto")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    func commonInit() {
        //        let height  = UIScreen.main.bounds.size.height
        //        heightConstraint.constant = height
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
//        publicSwitch.tintColor = UIColor.acGreen()
//        publicSwitch.onTintColor = UIColor.white
//        publicSwitch.thumbTintColor = UIColor.acGreen()
        
        publicSwitch.tintColor = UIColor.acGreen()
        publicSwitch.onTintColor = UIColor.acGreen()
        closeButton.title = String.fontAwesomeIcon(name: .doorClosed)
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
        if titleTextField.text!.count > 0 && choiceImage != nil && selectedJenreTag != nil {
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
    func convertedImageSize(size: CGSize) -> CGSize{
        let w = size.width
        let h = size.height
        let maxLength = CGFloat(300)
        var ratio: CGFloat!
        if h > w {
            ratio = maxLength / h
        } else {
            ratio = maxLength / w
        }
        let nW = w * ratio
        let nH = h * ratio
        return CGSize(width: nW, height: nH)
    }
    
    @IBAction func tapCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func tapDoneButton(_ sender: Any) {
        if publicFlag {
            saveServer(success: {  (docId, photo)  in
                print(docId)
                self.saveRealm(id: docId, postedImage: photo, success: {
                    print("アップドーロ成功！！")
                    NotificationCenter.default.post(name: .finishUpload, object: nil, userInfo: nil)
                }, failure: { (error) in
                    print(error)
                })
            }) { (error) in
                print(error)
            }
        } else {
            savePrivateRealm(success: {
                print("アップドーロ成功！！")
                NotificationCenter.default.post(name: .finishUpload, object: nil, userInfo: nil)
            }) { (error) in
                print(error)
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveServer(success: @escaping (_ id: String, _ photo: UIImage) -> Void, failure: @escaping (String) -> Void) {
        let originID = UUID().uuidString
        let postImage = choiceImage!.resize(size: convertedImageSize(size: choiceImage!.size))!
        let imageData = postImage.jpegData(compressionQuality: 0.3)!
        let storageRef = Storage.storage().reference(withPath: firePhotoCollection.path)
        let photoRef = storageRef.child(originID)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let uploadTask = photoRef.putData(imageData, metadata: metadata) { (metadata, error) in
            guard let metadata = metadata else {
                return failure("error upload storage")
            }
            print("metadata : ", metadata)
            photoRef.downloadURL(completion: { (url, error) in
                guard let downloadURL = url else {
                    print(error?.localizedDescription)
                    return failure("not found downloadURL")
                }
                let titleText = self.titleTextField.text!
                var newPhoto = OFirePhoto(id: originID,
                                          title: titleText,
                                          imageHeight: Int(postImage.size.height),
                                          imageWidth: Int(postImage.size.width),
                                          imageUrl: downloadURL.absoluteString,
                                          genre: self.selectedJenreTag!.getKey(),
                                          totalSaveCount: 1,
                                          weeklySaveCount: 1,
                                          weekStartDay: Date().dateAt(.startOfWeek).toString(),
                                          createdAt: Timestamp(date: Date()),
                                          updateAt: Timestamp(date: Date()),
                                          ownerId: GroupeDefaults.shared.authUid()!)
                let encoder = Firestore.Encoder()
                let newPhotoDoc = try! encoder.encode(newPhoto)
                self.firePhotoCollection.document(originID).setData(newPhotoDoc, completion: { (error) in
                    if let error = error {
                        print(error.localizedDescription)
                        failure("error save store")
                    } else {
                        print("success save firestore", originID)
                        success(originID, postImage)
                    }
                })
            })
        }
    }

    func saveRealm(id: String, postedImage: UIImage, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        let new = RealmPhoto.create(id: id,
                                    text: titleTextField.text!,
                                    image: postedImage,
                                    imageHeight: Int(postedImage.size.height),
                                    imageWidth: Int(postedImage.size.width),
                                    getDay: Date().toString(), isPublic: true,
                                    ownerId: GroupeDefaults.shared.authUid()!)
        RealmManager.shared.save(data: new, success: { () in
            success()
        }) { (error) in
            print(error)
            failure("realm save error")
        }
    }
    
    func savePrivateRealm(success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        
        let postImage = choiceImage!.resize(size: convertedImageSize(size: choiceImage!.size))!
        let new = RealmPhoto.create(id: UUID().uuidString,
                                    text: self.titleTextField.text!,
                                    image: postImage,
                                    imageHeight: Int(postImage.size.height),
                                    imageWidth: Int(postImage.size.width),
                                    getDay: Date().toString(),
                                    isPublic: false,
                                    ownerId: GroupeDefaults.shared.authUid()!)
        RealmManager.shared.save(data: new, success: { () in
            success()
        }) { (error) in
            print(error)
            failure("realm save error")
        }
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
            let beforeSeletedTag = genreListView.selectedTags().first
            beforeSeletedTag!.isSelected = false
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
