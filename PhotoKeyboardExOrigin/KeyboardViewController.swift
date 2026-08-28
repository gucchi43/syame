//
//  KeyboardViewController.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import SwiftUI
import os.log
import PhotoKeyboardFramework
import RealmSwift

/// キーボード拡張からURLを開くための透明なオーバーレイ。
///
/// iOS 18 以降、拡張からURLを開く手段は SwiftUI の `Link` しか残っていない。
/// レスポンダチェーンを辿って `openURL:` を perform する方法は塞がれ、
/// `extensionContext.open` はコンテナアプリのURLスキームに対しても false を返す
/// (実機で確認済み)。そのため既存のボタンの上にこのビューを重ね、タップを肩代わりさせる。
final class KeyboardLinkOverlayView: UIView {
    private let hostingController: UIHostingController<AnyView>

    init(url: URL, onTap: @escaping () -> Void) {
        hostingController = UIHostingController(rootView: AnyView(
            Link(destination: url) {
                // 見た目は下のボタンのままにしたいので透明にする。
                // contentShape を与えないと透明部分がタップを受け取らない。
                Color.clear.contentShape(Rectangle())
            }
            .simultaneousGesture(TapGesture().onEnded { onTap() })
        ))
        super.init(frame: .zero)

        backgroundColor = .clear
        let hosted = hostingController.view
        hosted?.backgroundColor = .clear
        hosted?.translatesAutoresizingMaskIntoConstraints = false
        guard let hosted = hosted else { return }
        addSubview(hosted)
        NSLayoutConstraint.activate([
            hosted.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosted.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosted.topAnchor.constraint(equalTo: topAnchor),
            hosted.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    /// 対象のビューにぴったり重ねる
    static func attach(url: URL, to target: UIView, in container: UIView, onTap: @escaping () -> Void) {
        let overlay = KeyboardLinkOverlayView(url: url, onTap: onTap)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: target.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: target.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: target.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: target.bottomAnchor)
        ])
    }
}

class KeyboardViewController: UIInputViewController, UITextFieldDelegate, RealmManagerDelegate {

    var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var homeButtonLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nextKeyboardButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var columnToggleButton: UIButton!
    @IBOutlet weak var boardChangeButton: UIButton!
    
    @IBOutlet weak var notFullBGView: UIView!
    @IBOutlet weak var notFullButton: UIButton!
    @IBOutlet weak var notFullLabel: UILabel!
    
    var textBoardFlag = false
    /// アセットが解決できなくてもキーボードの初期化自体は失敗させない

    
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
        applyHostKeyboardAppearance()
        baseSetUp()
        commonInit()
        collectionInit()
        attachLinkOverlays()

        if self.hasFullAccess {
            RealmManager.shared.delegate = self
            notFullInit(notFull: false)
            collectionView.reloadData()
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
            columnToggleButton.isEnabled = false
            columnToggleButton.tintColor = .gray
        } else {
            notFullBGView.isHidden = true
        }
    }
    
    /// URLを開くボタンにはSwiftUIのLinkを重ねる。詳細は KeyboardLinkOverlayView を参照。
    private func attachLinkOverlays() {
        if let url = URL(string: "\(KeyboardViewController.containerAppScheme)://") {
            KeyboardLinkOverlayView.attach(url: url, to: homeButton, in: view) {
                KeyboardViewController.log("tapped home link")
            }
        }
        if let url = URL(string: UIApplication.openSettingsURLString) {
            KeyboardLinkOverlayView.attach(url: url, to: notFullButton, in: view) {
                KeyboardViewController.log("tapped settings link")
            }
        }
    }

    func commonInit() {
        // 地は敷かない。
        //
        // iOS 26 のキーボードはシステム側が角丸のパネルとして描いており、
        // その上に自前の不透明な地を重ねると、わずかにずれた2枚目のパネルに見える。
        // 透かしてシステムの面をそのまま使うことで、地球儀とマイクの行まで
        // 地続きの1枚になる。角丸も自前で付けない(システムが既に丸めている)。
        self.view.backgroundColor = .clear
        homeButton.setTitleColor(.accent, for: .normal)
        homeButton.applySymbol(Symbol.home)
        
        columnToggleButton.setTitleColor(.accent, for: .normal)
        updateColumnToggleIcon()
        
        boardChangeButton.setTitleColor(.accent, for: .normal)
        boardChangeButton.applySymbol(Symbol.textMode)
        
        self.nextKeyboardButton.setTitleColor(.accent, for: .normal)
        self.nextKeyboardButton.applySymbol(Symbol.globe)
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        self.notFullBGView.backgroundColor = .clear
        self.notFullButton.titleLabel?.adjustsFontSizeToFitWidth = true
        // 文字色と影は AuroraButton が持つ
        self.notFullButton.applyCornerRadius(Radius.small)
        
        // 案内文は言語ごとに語順が変わるため、断片を連結せず1文として strings に置く。
        // 角括弧で囲んだ部分が太字になる
        self.notFullButton.setTitle(LocalizeKey.notFullButton.localizedString(), for: .normal)
        self.notFullLabel.attributedText = LocalizeKey.notFullGuide.localizedString()
            .emphasizingBracketed(base: UIFont.scaled(.footnote, weight: .regular),
                                  emphasis: UIFont.scaled(.footnote, weight: .bold),
                                  color: .textPrimary)
        generator.prepare()
    }
    
    func collectionInit() {
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.register(UINib(nibName: "TextCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TextCollectionViewCell")
        collectionView.backgroundColor = .clear
        collectionView.allowsMultipleSelection = false
        updateViewConstraints()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillLayoutSubviews() {
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
    
    /// 画像を並べる面の高さ。画面の半分では場所を取りすぎるため 0.35 に抑えている。
    /// 3列にしたことで1枚が小さくなり、低くしても同じ枚数が見える。
    private static let imageBoardHeightRatio: CGFloat = 0.35

    func setUpHeightConstraint() {
        var customHeight: CGFloat!
        if textBoardFlag {
            // 文字盤はキーの数と列数が固定なので、縮めると最終行が切れる
            customHeight = 200
        } else {
            customHeight = UIScreen.main.bounds.height * KeyboardViewController.imageBoardHeightRatio
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
    
    /// 並べ替えは持たない。本体アプリの一覧と同じ登録順で出す。
    /// キーボードとアプリで並びが違うと、目で覚えた位置が使えなくなる。
    func currentPhotos() -> Results<RealmPhoto> {
        return RealmManager.shared.realmData
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
        // 入力欄が切り替わるとホスト側の指定も変わりうるため、ここでも追従させる
        applyHostKeyboardAppearance()
    }

    /// ホストアプリが指定したキーボードの明暗に合わせる。
    ///
    /// キーボードの明暗は端末のダークモード設定ではなく、
    /// ホストアプリの keyboardAppearance で決まる。
    /// セマンティックカラーに任せるだけでは、明るいアプリの上で
    /// ペリペリだけが暗いという状態になる。
    private func applyHostKeyboardAppearance() {
        let style: UIUserInterfaceStyle
        switch textDocumentProxy.keyboardAppearance {
        case .dark:
            style = .dark
        case .light:
            style = .light
        default:
            // 指定なし。純正キーボードと同じく端末の設定に従う
            style = .unspecified
        }
        guard view.overrideUserInterfaceStyle != style else { return }
        view.overrideUserInterfaceStyle = style
    }
    
    func copyBoard() {
        // The Pasteboard is nil if full access is not granted
        guard let lastSelectedIndex = lastSelectedIndex,
              let photo = getPhoto(at: lastSelectedIndex),
              let selectImage = photo.image else {
            return
        }
        // 焼き込みの有無は Watermark 側で決まる。本体アプリからのコピーと結果を揃えるため、
        // ここで個別に合成しない
        selectImage.copyToPasteboardWithWatermark()
        updateUseNum(index: lastSelectedIndex.row)
    }
    
    func updateUseNum(index: Int) {
        guard index >= 0 && index < currentPhotos().count else { return }
        RealmManager.shared.incrementUseNum(id: currentPhotos()[index].id)
    }
    
    /// 拡張は実機でデバッガを繋ぎにくいため、操作の記録を端末のログと
    /// App Group の両方に残し、アプリ側からも確認できるようにする
    static func log(_ message: String) {
        os_log("%{public}@", log: OSLog(subsystem: "bocchi.PhotoKeyboardEx.PhotoKeyboardExOrigin", category: "openURL"), type: .info, message)
        GroupeDefaults.shared.setLastKeyboardOpenResult(message)
    }

    static let containerAppScheme = "photokeyboardex-app"

    static var containerAppURL: URL? {
        return URL(string: "\(containerAppScheme)://")
    }
    
    // ホーム/ヘルプ/設定への遷移は、ボタンに重ねた SwiftUI の Link が担当する。
    // 拡張から imperative に URL を開く手段が残っていないため、
    // これらの IBAction はタップを受け取らない。


    @IBAction func tapColumnToggleButton(_ sender: Any) {
        let next = imageColumns == GroupeDefaults.defaultKeyboardColumns
            ? GroupeDefaults.denseKeyboardColumns
            : GroupeDefaults.defaultKeyboardColumns
        GroupeDefaults.shared.setKeyboardColumns(next)
        updateColumnToggleIcon()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    /// 押した先の状態を出す。切り替えボタンの作法を boardChangeButton と揃える
    private func updateColumnToggleIcon() {
        let willBeDense = imageColumns == GroupeDefaults.defaultKeyboardColumns
        columnToggleButton.applySymbol(willBeDense ? Symbol.gridDense : Symbol.gridSparse)
    }
    
    @IBAction func tapBoardChangeButton(_ sender: Any) {
        textBoardFlag = !textBoardFlag
        // 高さの値を持つのは setUpHeightConstraint だけにする。
        // ここで直書きすると、比率を変えても文字盤から戻ったときだけ旧い値に戻る
        setUpHeightConstraint()
        if textBoardFlag {
            boardChangeButton.applySymbol(Symbol.imageMode)
            notFullBGView.isHidden = true
        } else {
            boardChangeButton.applySymbol(Symbol.textMode)
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
                if indexPath.row == currentPhotos().count {
                    cell.addCellconfigure()
                    if let url = KeyboardViewController.containerAppURL {
                        cell.attachOpenAppLink(url: url) {
                            KeyboardViewController.log("tapped add-photo cell link")
                        }
                    }
                } else {
                    cell.configure(photo: currentPhotos()[indexPath.row])
                    cell.isCheck = false
                }
            }
            return cell
        }
    }
    
    /// 文字盤はキーの数が決まっているため列数を変えない
    private static let textColumns = 10

    /// 利用者が選んだ列数。既定は3で、切り替えボタンで5にできる
    private var imageColumns: Int {
        return GroupeDefaults.shared.keyboardColumns()
    }

    /// キーボード自身の bounds で判定してはいけない。
    /// 文字盤に切り替えると高さが200になり、縦持ちのままでも幅が高さを上回って
    /// 横持ちと誤判定される(画像に戻したとき列数が倍になるのはこれが原因だった)。
    private var isLandscape: Bool {
        let screen = view.window?.windowScene?.screen.bounds ?? UIScreen.main.bounds
        return screen.width > screen.height
    }

    /// 列数から正方形セルの一辺を求める。
    /// 端数を切り上げると最後の1列がはみ出して折り返るため、必ず切り捨てる。
    private func gridCellSide(columns: Int) -> CGFloat {
        // レイアウト確定前は collectionView の幅がまだ 0 のことがあり、
        // そのまま計算すると全セルが潰れて何も見えなくなる
        let width = collectionView.bounds.width > 0 ? collectionView.bounds.width : view.bounds.width
        let available = width - Spacing.grid * CGFloat(columns - 1)
        guard available > 0 else { return 0 }
        return floor(available / CGFloat(columns))
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: Int
        if textBoardFlag {
            columns = KeyboardViewController.textColumns
        } else {
            // 横持ちは幅がおよそ2倍になるので列も倍にし、1枚の大きさを保つ
            columns = isLandscape ? imageColumns * 2 : imageColumns
        }
        let side = gridCellSide(columns: columns)
        return CGSize(width: side, height: side)
    }

    // 水平方向におけるセル間のマージン
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing.grid
    }

    // 垂直方向におけるセル間のマージン
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing.grid
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
            // AddCell への遷移はセルに重ねた SwiftUI の Link が担当するため、
            // ここでは何もしない
            if indexPath.row == currentPhotos().count {
                return
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
        }
    }
    
    fileprivate func getPhoto(at indexPath: IndexPath) ->  RealmPhoto? {
        // 末尾の要素番号は count - 1。count と等しい場合は追加ボタンのセルなので範囲外。
        guard indexPath.row >= 0 && indexPath.row < self.currentPhotos().count else { return nil }
        return self.currentPhotos()[indexPath.row]
    }
}

