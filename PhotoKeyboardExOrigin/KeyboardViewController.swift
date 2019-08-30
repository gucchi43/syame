//
//  KeyboardViewController.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import FontAwesome_swift
import PhotoKeyboardFramework
import Firebase
import Realm
import RealmSwift
import SwiftyAttributes

class KeyboardViewController: UIInputViewController, UITextFieldDelegate, RealmManagerDelegate {

    var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var homeButtonLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nextKeyboardButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var sortRankButton: UIButton!
    @IBOutlet weak var sortABCButton: UIButton!
    
    @IBOutlet weak var notFullBGView: UIView!
    @IBOutlet weak var notFullButton: UIButton!
    @IBOutlet weak var notFullLabel: UILabel!
    
//    @IBOutlet weak var searchBar: UISearchBar!
    //     var searchBar = UISearchBar()
    
    // photosの中にfavPhotos or abcPhotos が入る
    var favSortFlag = false
    var favPhotos: Results<RealmPhoto>!
    var abcPhotos: Results<RealmPhoto>!
    
    var items : NSArray = []
    private var searchResult = [String]()
    
    fileprivate var lastSelectedIndex: IndexPath?
    
    let generator = UINotificationFeedbackGenerator()
    
    override func updateViewConstraints() {
        super.updateViewConstraints()

        setUpHeightConstraint()
//        setUpWidthConstraint()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        var nib = UINib(nibName:"MainKBView", bundle:nil)
        var object = nib.instantiate(withOwner: self,options:nil)
        var v = object[0] as! UIView
        //                self.inputView!.addSubview(v)
        //        self.view.addSubview(v)
        view = v
        commonInit()
        generator.prepare()
        
        if self.hasFullAccess {
            print("FullAccess is true")
            favPhotos = RealmManager.shared.realmData.sorted(byKeyPath: "useNum")
            abcPhotos = RealmManager.shared.realmData.sorted(byKeyPath: "text")
            RealmManager.shared.delegate = self
            collectionInit()
            notFullInit(notFull: false)
            sortState()
        } else {
            print("FullAccess is false")
            notFullInit(notFull: true)
        }
    }
    
    func notFullInit(notFull: Bool) {
        if notFull {
            notFullBGView.isHidden = false
            sortRankButton.isEnabled = false
            sortABCButton.isEnabled = false
            sortRankButton.setTitleColor(.gray, for: .normal)
            sortABCButton.setTitleColor(.gray, for: .normal)
        } else {
            notFullBGView.isHidden = true
        }
    }
    
    func commonInit() {
        self.view.backgroundColor = .bgDark()
        homeButton.setTitleColor(.acGreen(), for: .normal)
        homeButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        homeButton.setTitle(String.fontAwesomeIcon(name: .home), for: .normal)
        
        helpButton.setTitleColor(.acGreen(), for: .normal)
        helpButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        helpButton.setTitle(String.fontAwesomeIcon(name: .question), for: .normal)
        
        sortRankButton.setTitleColor(.acGreen(), for: .normal)
        sortRankButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        sortRankButton.setTitle(String.fontAwesomeIcon(name: .sortAmountDown), for: .normal)
        
        sortABCButton.setTitleColor(.acGreen(), for: .normal)
        sortABCButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        sortABCButton.setTitle(String.fontAwesomeIcon(name: .sortAlphaDown), for: .normal)
        
        self.nextKeyboardButton.setTitleColor(.acGreen(), for: .normal)
        self.nextKeyboardButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        self.nextKeyboardButton.setTitle(String.fontAwesomeIcon(name: .globe), for: .normal)
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        self.notFullBGView.backgroundColor = .bgDark()
        self.notFullButton.backgroundColor = .acGreen()
        self.notFullButton.setTitle("設定画面へ", for: .normal)
        self.notFullButton.setTitleColor(.white, for: .normal)
        self.notFullButton.layer.cornerRadius = 8.0
        let notFullLabelStrig = "[KPB]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) + "→".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + "[キーボード]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) +
            "→".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + "[フルアクセスを許可する]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) + "をオンにしてください。".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white)
        self.notFullLabel.attributedText = notFullLabelStrig
    }
    
    func collectionInit() {
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.backgroundColor = .bgDark()
        collectionView.allowsMultipleSelection = false
        updateViewConstraints()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillLayoutSubviews() {
////        commonInit()
//
//        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        if self.needsInputModeSwitchKey {
            collectionViewBottomConstraint.constant = -self.nextKeyboardButton.frame.height
        } else {
            collectionViewBottomConstraint.constant = 0
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        setUpHeightConstraint()
        view.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func setUpHeightConstraint() {
        var customHeight: CGFloat!
        if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
            customHeight = UIScreen.main.bounds.height / 2
        } else {
            customHeight = UIScreen.main.bounds.height / 2
        }
        
        if heightConstraint == nil {
            heightConstraint = NSLayoutConstraint(item: view,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: customHeight)
            heightConstraint.priority = UILayoutPriority.required

            view.addConstraint(heightConstraint)
        }
        else {
            heightConstraint.constant = customHeight
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
    func currentPhotos() -> Results<RealmPhoto> {
        if favSortFlag {
            return favPhotos
        } else {
            return abcPhotos
        }
    }
    
    func sortState() {
        if favSortFlag {
            sortRankButton.setTitleColor(.acGreen(), for: .normal)
            sortABCButton.setTitleColor(.gray, for: .normal)
        } else {
            sortRankButton.setTitleColor(.gray, for: .normal)
            sortABCButton.setTitleColor(.acGreen(), for: .normal)
        }
        collectionView.reloadData()
    }
    
    func realmObjectDidChange() {
        print("realmデータの変更を検知")
//        collectionView.reloadData()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
//        var textColor: UIColor
//        let proxy = self.textDocumentProxy
//        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
//            textColor = UIColor.white
//        } else {
//            textColor = .bgDark()
//        }
//        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }
    
    func copyBoard() {
        guard let lastSelectedIndex = lastSelectedIndex else {
            return
        }
        let pasetImage = currentPhotos()[lastSelectedIndex.row].image!
        // The Pasteboard is nil if full access is not granted
        // 'image' is the UIImage you about to copy to the pasteboard
        
        print("pasetImage : ", pasetImage)
        
        let pb = UIPasteboard.general
        let type = UIPasteboard.typeListImage[0] as! String
        if !type.isEmpty {
            pb.setData(pasetImage.pngData()!, forPasteboardType: type)
            if let readData = pb.data(forPasteboardType: type) {
                let readImage = UIImage(data: readData, scale: 2)
                print("\(pasetImage) == \(String(describing: pb.image)) == \(String(describing: readImage))")
                updateUseNum(index: lastSelectedIndex.row)
            }
        }
    }
    
    func updateUseNum(index: Int) {
        let updateValue = numUpdatePhoto(current: currentPhotos()[index])
        RealmManager.shared.update(data: updateValue, success: { () in
        }) { (error) in
            print(error)
        }
    }
    
    func goMainApp() {
        let url = URL(string: "photokeyboardex-app://")!
        
        let selector = sel_registerName("openURL:")
        var responder = self as UIResponder?
        while let r = responder, !r.responds(to: selector) {
            responder = r.next
        }
        _ = responder?.perform(selector, with: url)
    }
    
    @IBAction func tapHomeButton(_ sender: Any) {
        goMainApp()
    }
    
    @IBAction func tapHelpButton(_ sender: Any) {
        if self.hasFullAccess {
            print("FullAccess is true")
            self.openAppSettings()
        } else {
            print("FullAccess is false")
            self.openAppSettings()
        }
    }
    
    @IBAction func tapSortRankButton(_ sender: Any) {
        favSortFlag = true
        sortState()
    }
    @IBAction func tapSortABCButton(_ sender: Any) {
        favSortFlag = false
        sortState()
    }
    
    @IBAction func tapNotFullButton(_ sender: Any) {
      openAppSettings()
    }
    
    func openAppSettings() {
        var responder: UIResponder? = self
        var sharedApplication: UIResponder?
        while responder != nil {
            if let application = responder as? UIApplication {
                sharedApplication = application
                break
            }
            responder = responder?.next
        }
        
        guard let application = sharedApplication else { return }
        
        if #available(iOS 11.0, *) {
            application.perform(#selector(UIApplication.openURL(_:)), with: URL(string: UIApplication.openSettingsURLString))
        } else {
            if #available(iOS 10.0, *) {
                application.perform("openURL:", with: URL(string: "App-Prefs:root=General&path=Keyboard/KEYBOARDS"))
            } else {
                application.perform("openURL:", with: URL(string: "prefs:root=General&path=Keyboard/KEYBOARDS"))
            }
        }
    }
    
    
    func numUpdatePhoto(current: RealmPhoto) -> RealmPhoto {
        let new = RealmPhoto()
        new.id = current.id
        new.text = current.text
        new.image = current.image
        new.imageHeight = current.imageHeight
        new.imageWidth = current.imageWidth
        new.getDay = current.getDay
        new.useNum = current.useNum + 1
        return new
    }
}


extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return currentPhotos().count
        return currentPhotos().count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        if let cell = cell as? PhotoCollectionViewCell {
//            if let lastSelectedIndex = lastSelectedIndex, lastSelectedIndex == indexPath {
//                cell.configure(photo: photos![indexPath.row], isSelected: true)
//            } else {
//                cell.configure(photo: photos![indexPath.row], isSelected: false)
//            }
            if indexPath.row == currentPhotos().count {
                cell.addCellconfigure()
            } else {
                cell.configure(photo: currentPhotos()[indexPath.row])
                cell.isCheck = false
            }
//            }
            print("cell 生成 index: ", indexPath.row)}
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //　横幅を画面サイズの約半分にする
        if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
            let cellSize:CGFloat = self.view.bounds.width/4 - 1.5
            return CGSize(width: cellSize, height: cellSize)
        } else {
            let cellSize:CGFloat = self.view.bounds.width/2 - 0.5
            return CGSize(width: cellSize, height: cellSize)
        }
    }
    
    // 水平方向におけるセル間のマージン
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
    
    // 垂直方向におけるセル間のマージン
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
}

extension KeyboardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        var newValue = self.getModel(at: indexPath) as! Model
//
//        guard var newValue = self.getPhoto(at: indexPath) else { return }
        
        print("=========")
        print("call didDeselectItemAt")
        print("indexpath : ", indexPath)
//        print("newValue : ", self.getPhoto(at: indexPath)!)
        print("=========")
        
        print("didDeselectItemAt 更新前のphoto : ", currentPhotos()[indexPath.row])
//        self.getPhoto(at: indexPath)!.isSelected = false
        print("didDeselectItemAt 更新前のphoto : ", currentPhotos()[indexPath.row])
//        newValue.isSelected = false
//        models[indexPath.row] = newValue
        
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            return //the cell is not visible
        }
        cell.isCheck = false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        
        // AddCell,管理アプリへ遷移
//        if indexPath.row == currentPhotos().count + 1 {
        if indexPath.row == currentPhotos().count {
            goMainApp()
        } else {
            // 未選択->選択済み
            guard let lastSelectedIndex = self.lastSelectedIndex, lastSelectedIndex == indexPath else {
                print("=========")
                print("call didSelectItemAt 通常モード")
                print("indexpath : ", indexPath)
                print("=========")
                self.lastSelectedIndex = indexPath
                cell.isCheck = true
                print("didSelectItemAt 通常モード 更新前のphoto : ", currentPhotos()[indexPath.row])
                //            let updateValue = numUpdatePhoto(current: currentPhotos()[indexPath.row])
                //            RealmManager.shared.update(data: updateValue, success: { () in
                //            }) { (error) in
                //                print(error)
                //            }
                print("didSelectItemAt 通常モード 更新後のphoto : ", currentPhotos()[indexPath.row])
                self.copyBoard()
                
                self.tapAnimation(cell: cell)
                return
            }
            // 選択済み->選択解除
            print("=========")
            print("call didSelectItemAt 解除モード")
            print("indexpath : ", indexPath)
            print("=========")
            
            self.collectionView.deselectItem(at: indexPath, animated: true)
            self.lastSelectedIndex = nil
            cell.isCheck = false
            print("didSelectItemAt 解除モード 更新前のphoto : ", currentPhotos()[indexPath.row])
            
            //        guard var newValue = self.getPhoto(at: indexPath) else { return }
            //        newValue.isSelected = false
            RealmManager.shared.update(data: self.getPhoto(at: indexPath)!, success: { () in
                print()
            }) { (error) in
                print(error)
            }
            print("didSelectItemAt 解除モード 更新後のphoto : ", currentPhotos()[indexPath.row])
        }
        
        
    }
    
    private func tapAnimation(cell: PhotoCollectionViewCell) {
        cell.choiceCoverView.play()
        cell.choiceCoverView.play { (finish) in
            self.generator.notificationOccurred(.success)
            print("コール アニメーション row: ")
//            let choiceColor = ColorManager.shared.acRandom()
//            cell.choiceCoverLabel.textColor = choiceColor
//            cell.choiceCover2View.backgroundColor = choiceColor
//            cell.choiceCover2View.isHidden = false
//            cell.choiceCoverLabel.isHidden = false
        }
    }
    
    fileprivate func getPhoto(at indexPath: IndexPath) ->  RealmPhoto? {
        guard !self.currentPhotos().isEmpty && indexPath.row >= 0 && indexPath.row <= self.currentPhotos().count else { return nil }
        return self.currentPhotos()[indexPath.row]
    }
}

