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

class KeyboardViewController: UIInputViewController, UITextFieldDelegate, RealmManagerDelegate {
//    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    var widthConstraint2: NSLayoutConstraint!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var nextKeyboardButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var sortRankButton: UIButton!
    @IBOutlet weak var sortABCButton: UIButton!
    
//    @IBOutlet weak var searchBar: UISearchBar!
    //     var searchBar = UISearchBar()
    
    var photos = RealmManager.shared.realmData
    
    var items : NSArray = []
    private var searchResult = [String]()
    
    fileprivate var lastSelectedIndex: IndexPath?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        // Add custom view sizing constraints here
        if (view.frame.size.width == 0 || view.frame.size.height == 0) {
            return
        }
        setUpHeightConstraint()
//        setUpWidthConstraint()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseApp.configure()
        var v = UINib(nibName:"MainKBView", bundle:nil).instantiate(withOwner: self,options:nil)[0] as! UIView
        //        self.inputView!.addSubview(v)
        view = v
        RealmManager.shared.delegate = self
        collectionInit()
        commonInit()
        sortState(rankFlag: true)
//        let xibView = MainKBView(frame: CGRect(x: 0, y: 0, width: 300, height: 216))
//        view.addSubview(xibView)
    }

    func commonInit() {
        self.view.backgroundColor = .bgDark()
        
        homeButton.setTitleColor(.acGreen(), for: .normal)
        helpButton.setTitleColor(.acGreen(), for: .normal)
        sortRankButton.setTitleColor(.acGreen(), for: .normal)
        sortABCButton.setTitleColor(.acGreen(), for: .normal)
    
        // Perform custom UI setup here
        self.nextKeyboardButton = UIButton(type: .system)
        
        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        self.view.addSubview(self.nextKeyboardButton)
        
        self.nextKeyboardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//        searchBar = UISearchBar()
//        searchBar.delegate = self
//        searchBar.frame = CGRect(x:0, y:0, width:self.view.frame.width, height:44)
////        searchBar.layer.position = CGPoint(x: self.view.bounds.width/2, y: 89)
//        searchBar.searchBarStyle = UISearchBar.Style.default
//        searchBar.showsSearchResultsButton = false
//        collectionView.contentOffset = CGPoint(x: 0, y: searchBar.frame.height)
//        searchBar.placeholder = "検索"
//        searchBar.setValue("キャンセル", forKey: "_cancelButtonText")
//        searchBar.tintColor = UIColor.red
//
//        collectionView.addSubview(searchBar)
    }
    
    func collectionInit() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.backgroundColor = .bgDark()
        collectionView.allowsMultipleSelection = false
    }
    
    override func viewWillLayoutSubviews() {
////        commonInit()
//
//        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//                comzmonInit()
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
//        heightConstraint2.constant = 500
//        self.view.addConstraint(heightConstraint2)
        if self.hasFullAccess {
            print("FullAccess is true")
        } else {
            print("FullAccess is false")
//            self.extensionContext?.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: nil)

        }
    }
    
    func setUpHeightConstraint() {
        let customHeight = UIScreen.main.bounds.height / 2
        
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
    
    func setUpWidthConstraint() {
        let customWidth = UIScreen.main.bounds.width
        
        if widthConstraint2 == nil {
            widthConstraint2 = NSLayoutConstraint(item: view,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: customWidth)
            widthConstraint2.priority = UILayoutPriority.required
            
            view.addConstraint(widthConstraint2)
        }
        else {
            widthConstraint2.constant = customWidth
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
//    // 渡された文字列を含む要素を検索する。
//    func searchItems(searchText: String){
////        // 要素を検索する。
////        if searchText != "" {
////            searchResult = models..filter { item in
////                return (item as! String).contains(searchText)
////                } as NSArray
////        }else{
////            // 渡された文字列が空の場合は全てを表示する。
////            searchResult = items
////        }
//    }
//
//    // SearchBarのデリゲードメソッド
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        // キャンセルされた場合、検索は行わない。
////        searchBar.text = ""
////        self.view.endEditing(true)
////        searchResult = items
//    }
//
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        // キーボードを閉じる。
//        self.view.endEditing(true)
//    }
    
    func sortState(rankFlag: Bool) {
        if rankFlag {
            sortRankButton.setTitleColor(.acGreen(), for: .normal)
            sortABCButton.setTitleColor(.gray, for: .normal)
        } else {
            sortRankButton.setTitleColor(.gray, for: .normal)
            sortABCButton.setTitleColor(.acGreen(), for: .normal)
        }
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
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = .bgDark()
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }
    
    func copyBoard() {
        guard let lastSelectedIndex = lastSelectedIndex else {
            return
        }
        let pasetImage = photos![lastSelectedIndex.row].image!
        // The Pasteboard is nil if full access is not granted
        // 'image' is the UIImage you about to copy to the pasteboard
        let pb = UIPasteboard.general
        let type = UIPasteboard.typeListImage[0] as! String
        if !type.isEmpty {
            pb.setData(pasetImage.pngData()!, forPasteboardType: type)
            if let readData = pb.data(forPasteboardType: type) {
                let readImage = UIImage(data: readData, scale: 2)
                print("\(pasetImage) == \(String(describing: pb.image)) == \(String(describing: readImage))")
            }
        }
    }
    
    @IBAction func tapHomeButton(_ sender: Any) {
        let url = URL(string: "photokeyboardex-app://")!
        
        let selector = sel_registerName("openURL:")
        var responder = self as UIResponder?
        while let r = responder, !r.responds(to: selector) {
            responder = r.next
        }
        _ = responder?.perform(selector, with: url)
    }
    
    @IBAction func tapHelpButton(_ sender: Any) {
        if self.hasFullAccess {
            print("FullAccess is true")
        } else {
            print("FullAccess is false")
                        self.extensionContext?.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: nil)
        }
    }
    
    @IBAction func tapSortRankButton(_ sender: Any) {
        sortState(rankFlag: true)
    }
    @IBAction func tapSortABCButton(_ sender: Any) {
        sortState(rankFlag: false)
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
        return photos?.count ??  0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        if let cell = cell as? PhotoCollectionViewCell {
//            if let lastSelectedIndex = lastSelectedIndex, lastSelectedIndex == indexPath {
//                cell.configure(photo: photos![indexPath.row], isSelected: true)
//            } else {
//                cell.configure(photo: photos![indexPath.row], isSelected: false)
//            }
                cell.configure(photo: photos![indexPath.row])
                cell.isCheck = false
//            }
            print("cell 生成 index: ", indexPath.row)}
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //　横幅を画面サイズの約半分にする
        let cellSize:CGFloat = self.view.bounds.width/2 - 0.5
        return CGSize(width: cellSize, height: cellSize)
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
        
        print("didDeselectItemAt 更新前のphoto : ", photos![indexPath.row])
//        self.getPhoto(at: indexPath)!.isSelected = false
        print("didDeselectItemAt 更新前のphoto : ", photos![indexPath.row])
//        newValue.isSelected = false
//        models[indexPath.row] = newValue
        
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            return //the cell is not visible
        }
        cell.isCheck = false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        // 未選択->選択済み
        guard let lastSelectedIndex = self.lastSelectedIndex, lastSelectedIndex == indexPath else {
            print("=========")
            print("call didSelectItemAt 通常モード")
            print("indexpath : ", indexPath)
            print("=========")
            self.lastSelectedIndex = indexPath
            cell.isCheck = true
            print("didSelectItemAt 通常モード 更新前のphoto : ", photos![indexPath.row])
            let updateValue = numUpdatePhoto(current: photos![indexPath.row])
            RealmManager.shared.update(data: updateValue, success: { () in
            }) { (error) in
                print(error)
            }
            print("didSelectItemAt 通常モード 更新後のphoto : ", photos![indexPath.row])
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
        print("didSelectItemAt 解除モード 更新前のphoto : ", photos![indexPath.row])
        
//        guard var newValue = self.getPhoto(at: indexPath) else { return }
//        newValue.isSelected = false
        RealmManager.shared.update(data: self.getPhoto(at: indexPath)!, success: { () in
            print()
        }) { (error) in
            print(error)
        }
        print("didSelectItemAt 解除モード 更新後のphoto : ", photos![indexPath.row])
        
    }
    
    private func tapAnimation(cell: PhotoCollectionViewCell) {
        cell.choiceCoverView.play()
        cell.choiceCoverView.play { (finish) in
            print("コール アニメーション row: ")
//            let choiceColor = ColorManager.shared.acRandom()
//            cell.choiceCoverLabel.textColor = choiceColor
//            cell.choiceCover2View.backgroundColor = choiceColor
//            cell.choiceCover2View.isHidden = false
//            cell.choiceCoverLabel.isHidden = false
        }
    }
    
    fileprivate func getPhoto(at indexPath: IndexPath) ->  RealmPhoto? {
        guard !self.photos!.isEmpty && indexPath.row >= 0 && indexPath.row <= self.photos!.count else { return nil }
        return self.photos![indexPath.row]
    }
}

