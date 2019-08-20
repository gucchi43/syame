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
import Ballcap

class AddViewController: UIViewController {

//    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var genreListView: TagListView!
    var choiceImage: UIImage!
    var postImage: UIImage!
    var selectedJenreTag: GenreTagType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    func commonInit() {
//        let height  = UIScreen.main.bounds.size.height
//        heightConstraint.constant = height
        navigationItem.title = "コトバを追加しよう"
        titleLabel.textColor = .white
        genreLabel.textColor = .white
        view.backgroundColor = .bgDark()
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),
                            for: UIControl.Event.editingChanged)
        if let image = choiceImage {
            imageView.image = image
        }
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
    
    func convertedImageSize(size: CGSize) -> CGSize{
        let w = size.width
        let h = size.height
        let maxLength = CGFloat(400)
        if h > maxLength || w > maxLength {
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
        return size
    }
    
    @IBAction func tapCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func tapDoneButton(_ sender: Any) {
        saveServer(success: {  (docId) in
            self.saveRealm(id: docId, success: {
                print("アップドーロ成功！！")
            }, failure: { (error) in
                print(error)
            })
        }) { (error) in
            print(error)
        }
//        saveRealm()
        self.dismiss(animated: true, completion: nil)
    }

    func saveServer(success: @escaping (String) -> Void, failure: @escaping (String) -> Void) {
        
        postImage = choiceImage!.resize(size: convertedImageSize(size: choiceImage!.size))
        let photoDoc = Document<FirePhoto>.init()
        let file: File = File(photoDoc.storageReference, data: postImage.jpegData(compressionQuality: 0.5), mimeType: .jpeg)
        let task = file.save { (metadata, error) in
            if let error = error {
                print(error)
                failure("file seve error")
            } else {
                photoDoc.data?.title = self.titleTextField.text!
                photoDoc.data?.genre = self.selectedJenreTag!.getKey()
                photoDoc.data?.saveCount = 1
                photoDoc.data?.imageHeight = Int(self.postImage!.size.height)
                photoDoc.data?.imageWidth = Int(self.postImage!.size.width)
                // upload
                photoDoc.data?.image = file
                photoDoc.save(completion: { (error) in
                    if let error = error {
                        print(error)
                        failure("firePhoto save error")
                    } else {
                        success(photoDoc.id)
                    }
                })
            }
        }
        
    }

    func saveRealm(id: String, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        let new = RealmPhoto.create(id: id,
                                    text: titleTextField.text!,
                                    image: postImage!,
                                    imageHeight: Int(postImage!.size.height),
                                    imageWidth: Int(postImage!.size.width),
                                    getDay: Date().toString())
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
