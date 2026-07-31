//
//  KeyboardViewController.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import os.log
import PhotoKeyboardFramework
import Realm
import RealmSwift

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
    @IBOutlet weak var boardChangeButton: UIButton!
    
    @IBOutlet weak var notFullBGView: UIView!
    @IBOutlet weak var notFullButton: UIButton!
    @IBOutlet weak var notFullLabel: UILabel!
    
    var textBoardFlag = false
    /// アセットが解決できなくてもキーボードの初期化自体は失敗させない
    let logoImage = UIImage(named: "photo_logo_2")
    
//    @IBOutlet weak var searchBar: UISearchBar!
    //     var searchBar = UISearchBar()
    
    // photosの中にfavPhotos or abcPhotos が入る
    var favSortFlag = false
    // フルアクセス未許可でも currentPhotos() が nil 参照にならないよう遅延生成にする
    lazy var favPhotos: Results<RealmPhoto> = RealmManager.shared.realmData.sorted(byKeyPath: "useNum")
    lazy var abcPhotos: Results<RealmPhoto> = RealmManager.shared.realmData.sorted(byKeyPath: "text")
    
    var items : NSArray = []
    private var searchResult = [String]()
    
    fileprivate var lastSelectedIndex: IndexPath?
    
    let generator = UINotificationFeedbackGenerator()
    
    let textArray = ["q","w","e","r","t","y","u","i","o","p","a","s","d","f","g","h","j","k","l","@","z","x","c","v","b","n","m","!","?","0","1","2","3","4","5","6","7","8","9","×"]
    override func updateViewConstraints() {
        super.updateViewConstraints()

        setUpHeightConstraint()
//        setUpWidthConstraint()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        baseSetUp()
        commonInit()
        collectionInit()
        
        if self.hasFullAccess {
            RealmManager.shared.delegate = self
            notFullInit(notFull: false)
            sortState()
        } else {
            notFullInit(notFull: true)
        }
    }

    func baseSetUp() {
        let nib = UINib(nibName: "MainKBView", bundle: nil)
        let object = nib.instantiate(withOwner: self, options: nil)
        // xibが読み込めない場合でもクラッシュさせず、既定のviewのまま続行する
        guard let v = object.first as? UIView else { return }
        view = v
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
        
        boardChangeButton.setTitleColor(.acGreen(), for: .normal)
        boardChangeButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        boardChangeButton.setTitle(String.fontAwesomeIcon(name: .font), for: .normal)
        
        self.nextKeyboardButton.setTitleColor(.acGreen(), for: .normal)
        self.nextKeyboardButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 20, style: .solid)
        self.nextKeyboardButton.setTitle(String.fontAwesomeIcon(name: .globe), for: .normal)
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        self.notFullBGView.backgroundColor = .bgDark()
        self.notFullButton.backgroundColor = .acGreen()
        self.notFullButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.notFullButton.setTitleColor(.white, for: .normal)
        self.notFullButton.layer.cornerRadius = 8.0
        
        if Lang.langRootKey() == "JP" {
            self.notFullButton.setTitle("設定画面へ", for: .normal)
            let notFullLabelStrig = "[PKB]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) + "→".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + "[キーボード]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) +
                "→".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + "[フルアクセスを許可する]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) + "をオンにしてください。".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white)
            self.notFullLabel.attributedText = notFullLabelStrig
        } else {
            self.notFullButton.setTitle("Go to setting", for: .normal)
            let notFullLabelStrig = "[PKB]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) + "→".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + "[Keyboards]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) +
                "→".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + "Turn on ".withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + "[Allow Full Access]".withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white)
            self.notFullLabel.attributedText = notFullLabelStrig
        }
        generator.prepare()
        
        // 多言語対応がうまくいかずとりあえずコメントアウト
//        if Lang.langRootKey() == "JP" {
//            let notFullLabelStrig = LocalizeKey.notFullLabelFirst.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) + LocalizeKey.notFullLabelSecond.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + LocalizeKey.notFullLabelThird.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) +
//                LocalizeKey.notFullLabelSecond.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + LocalizeKey.notFullLabelFourth.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + LocalizeKey.notFullLabelFifth.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white)
//            self.notFullLabel.attributedText = notFullLabelStrig
//        } else {
//            let notFullLabelStrig = LocalizeKey.notFullLabelFirst.localizedString() .withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) + LocalizeKey.notFullLabelSecond.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + LocalizeKey.notFullLabelThird.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white) +
//                LocalizeKey.notFullLabelSecond.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + LocalizeKey.notFullLabelFifth.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .regular)).withTextColor(.white) + LocalizeKey.notFullLabelFourth.localizedString().withFont(Font.systemFont(ofSize: 14, weight: .bold)).withTextColor(.white)
//            self.notFullLabel.attributedText = notFullLabelStrig
//        }
    }
    
    func collectionInit() {
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.register(UINib(nibName: "TextCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TextCollectionViewCell")
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
        if textBoardFlag {
            customHeight = 200
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
        // 本体アプリで画像を追加/削除した結果をキーボードにも反映する
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
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
        // The Pasteboard is nil if full access is not granted
        guard let lastSelectedIndex = lastSelectedIndex,
              let photo = getPhoto(at: lastSelectedIndex),
              let selectImage = photo.image else {
            return
        }
        // ロゴが取得できない場合は合成せず元画像をそのまま貼り付ける
        let pasetImage = logoImage.flatMap { selectImage.composite(image: $0, rate: 1.0) } ?? selectImage
        pasetImage.copyToGeneralPasteboard()
        updateUseNum(index: lastSelectedIndex.row)
    }
    
    func updateUseNum(index: Int) {
        guard index >= 0 && index < currentPhotos().count else { return }
        RealmManager.shared.incrementUseNum(id: currentPhotos()[index].id)
    }
    
    /// キーボード拡張からURLを開く。
    ///
    /// 以前はレスポンダチェーンを遡って `openURL:` を perform していたが、現行のiOSでは
    /// 拡張のレスポンダチェーンに UIApplication が存在しないため何も起きない。
    /// 拡張から画面遷移する正規の方法は extensionContext.open。
    /// 外部URLは直接開けないことがあるので、その場合はコンテナアプリ経由で開かせる。
    private func open(_ url: URL) {
        guard let context = extensionContext else {
            KeyboardViewController.log("extensionContext is nil: \(url)")
            return
        }
        context.open(url) { [weak self] success in
            KeyboardViewController.log("extensionContext.open(\(url)) -> \(success)")
            guard !success else { return }
            self?.openViaContainerApp(url)
        }
    }

    /// 拡張は実機でデバッガを繋ぎにくいため、URLオープンの結果を端末のログと
    /// App Group の両方に残し、アプリ側からも確認できるようにする
    static func log(_ message: String) {
        os_log("%{public}@", log: OSLog(subsystem: "bocchi.PhotoKeyboardEx.PhotoKeyboardExOrigin", category: "openURL"), type: .info, message)
        GroupeDefaults.shared.setLastKeyboardOpenResult(message)
    }

    /// コンテナアプリを起動し、開きたいURLを渡して代わりに開いてもらう
    private func openViaContainerApp(_ url: URL) {
        var components = URLComponents()
        components.scheme = KeyboardViewController.containerAppScheme
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
        guard let forwardURL = components.url else { return }
        extensionContext?.open(forwardURL) { success in
            KeyboardViewController.log("container app fallback(\(forwardURL)) -> \(success)")
        }
    }

    private static let containerAppScheme = "photokeyboardex-app"

    func goMainApp() {
        guard let url = URL(string: "\(KeyboardViewController.containerAppScheme)://") else { return }
        open(url)
    }
    
    @IBAction func tapHomeButton(_ sender: Any) {
        goMainApp()
    }
    
    @IBAction func tapHelpButton(_ sender: Any) {
        self.openOfficialLINE()
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
    
    @IBAction func tapBoardChangeButton(_ sender: Any) {
        textBoardFlag = !textBoardFlag
        if textBoardFlag {
            heightConstraint.constant = 200
            boardChangeButton.setTitle(String.fontAwesomeIcon(name: .images), for: .normal)
            notFullBGView.isHidden = true
        } else {
            heightConstraint.constant = UIScreen.main.bounds.height / 2
            boardChangeButton.setTitle(String.fontAwesomeIcon(name: .font), for: .normal)
            if self.hasFullAccess {
                notFullBGView.isHidden = true
            } else {
                notFullBGView.isHidden = false
            }
        }
        collectionView.reloadData {
            print("collectionView 更新完了 textBoardFlag -> ",self.textBoardFlag)
        }
    }
    
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        open(url)
    }

    func openOfficialLINE() {
        guard let url = URL(string: "https://line.me/ti/p/%40gox9644r") else { return }
        open(url)
    }


}


extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if textBoardFlag {
            return textArray.count
        } else {
            if self.hasFullAccess {
                // +1は最後のCellの追加ボタンCell分
                return currentPhotos().count + 1
            } else {
                return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if textBoardFlag {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextCollectionViewCell", for: indexPath)
            if let cell = cell as? TextCollectionViewCell {
                cell.configure(content: textArray[indexPath.row])
            }
            return cell
        } else {
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
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if textBoardFlag {
            //　横幅を画面の10等分
            if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
                let cellSize:CGFloat = self.view.bounds.width/10 - 2.7
                return CGSize(width: cellSize, height: cellSize)
            } else {
                let cellSize:CGFloat = self.view.bounds.width/10 - 2.7
                return CGSize(width: cellSize, height: cellSize)
            }
        } else {
            //　横幅を画面サイズの約半分にする
            if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
                let cellSize:CGFloat = self.view.bounds.width/4 - 1.5
                return CGSize(width: cellSize, height: cellSize)
            } else {
                let cellSize:CGFloat = self.view.bounds.width/2 - 0.5
                return CGSize(width: cellSize, height: cellSize)
            }
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
        if textBoardFlag == false{
            guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
                return //the cell is not visible
            }
            cell.isCheck = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if textBoardFlag {
            if textArray[indexPath.row] == "×" {
                self.textDocumentProxy.deleteBackward()
            } else {
                textDocumentProxy.insertText(textArray[indexPath.row])
            }
        } else {
            // AddCell,管理アプリへ遷移
            //        if indexPath.row == currentPhotos().count + 1 {
            if indexPath.row == currentPhotos().count {
                goMainApp()
            } else {
                // 画面外のセルや種類の異なるセルではnilになるためクラッシュさせない
                guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
                    return
                }
                // 未選択->選択済み
                guard let lastSelectedIndex = self.lastSelectedIndex, lastSelectedIndex == indexPath else {
                    self.lastSelectedIndex = indexPath
                    cell.isCheck = true
                    self.copyBoard()
                    GroupeDefaults.shared.incrementSendCount()
                    self.tapAnimation(cell: cell)
                    return
                }
                // 選択済み->選択解除
                // 管理済みオブジェクトを書き戻しても内容は変わらないので保存はしない
                self.collectionView.deselectItem(at: indexPath, animated: true)
                self.lastSelectedIndex = nil
                cell.isCheck = false
                cell.choiceCoverView.stop()
            }
        }
    }
    
    private func tapAnimation(cell: PhotoCollectionViewCell) {
        // 二重に play するとアニメーションが再スタートし、完了ハンドラも二重に走る
        cell.choiceCoverView.stop()
        cell.choiceCoverView.play { [weak self] (finish) in
            self?.generator.notificationOccurred(.success)
//            let choiceColor = ColorManager.shared.acRandom()
//            cell.choiceCoverLabel.textColor = choiceColor
//            cell.choiceCover2View.backgroundColor = choiceColor
//            cell.choiceCover2View.isHidden = false
//            cell.choiceCoverLabel.isHidden = false
        }
    }
    
    fileprivate func getPhoto(at indexPath: IndexPath) ->  RealmPhoto? {
        // 末尾の要素番号は count - 1。count と等しい場合は追加ボタンのセルなので範囲外。
        guard indexPath.row >= 0 && indexPath.row < self.currentPhotos().count else { return nil }
        return self.currentPhotos()[indexPath.row]
    }
}

