//
//  AddViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import StoreKit
import PhotoKeyboardFramework
import SwiftDate

class AddViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publicLabel: UILabel!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!

    @IBOutlet weak var publicSwitch: UISwitch!
    var choiceImage: UIImage! //選択された元画像

    /// 一般ユーザーによる公開投稿は停止したため常に false。
    /// 画像はサーバへ送らず端末内のRealmにのみ保存する。
    var publicFlag = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        observeKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - キーボード回避

    /// タイトル入力欄は画面の下半分にあり、キーボードが出ると隠れて何を打っているか見えなくなる。
    /// スクロール領域を縮めたうえで入力欄まで送る。
    private func observeKeyboard() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                           name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                           name: UIResponder.keyboardWillHideNotification, object: nil)

        // 入力欄の外を触ったら閉じられるようにする。閉じる手段が無いと下の完了ボタンも押せない
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        // キーボードの高さは画面座標で来るため、自分の座標系に直してから重なりを測る
        let overlap = scrollView.convert(frame, from: nil).intersection(scrollView.bounds).height
        guard overlap > 0 else {
            resetInsets()
            return
        }
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
        scrollView.scrollRectToVisible(visibleRectForTitleField(), animated: true)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        resetInsets()
    }

    private func resetInsets() {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    /// 入力欄だけを送ると見出しが隠れて何の入力なのか分からなくなるため、ラベルごと収める
    private func visibleRectForTitleField() -> CGRect {
        let field = scrollView.convert(titleTextField.bounds, from: titleTextField)
        let label = scrollView.convert(titleLabel.bounds, from: titleLabel)
        return field.union(label).insetBy(dx: 0, dy: -Spacing.m)
    }
    
    func commonInit() {
        navigationItem.title = LocalizeKey.addNavTitle.localizedString()
        doneButton.setTitle(LocalizeKey.addDone.localizedString() , for: .normal)
        titleLabel.text = LocalizeKey.addInputTitle.localizedString()
        publicLabel.text = LocalizeKey.addPublicSwitchOn.localizedString()
        titleLabel.textColor = .textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        publicLabel.textColor = .textPrimary
        publicLabel.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .bgBase
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)),
                                 for: UIControl.Event.editingChanged)
        if let image = choiceImage {
            imageView.image = image
        }
        // 公開投稿を停止したため、公開/非公開の切り替えUIは出さない
        publicSwitch.isOn = false
        publicSwitch.isHidden = true
        publicLabel.isHidden = true
        closeButton.applySymbol(Symbol.close)
        addButtonState()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        addButtonState()
    }
    
    func addButtonState() {
        let canSubmit = !(titleTextField.text ?? "").isEmpty && choiceImage != nil
        doneButton.isEnabled = canSubmit
        // 文字色と影は AuroraButton が持つ
        // AuroraButton は layer 自体がグラデーションなので、
        // backgroundColor を薄めても地の色は変わらない。無効状態は透明度で出す
        doneButton.alpha = canSubmit ? 1.0 : 0.4
    }
    
    /// Storyboardからの接続が残っているため定義だけ残す。
    /// 公開投稿は停止したので、操作されても非公開のまま固定する。
    @IBAction func switchChanged(_ sender: UISwitch) {
        sender.isOn = false
        publicFlag = false
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
        case realmSaveFailed
        case limitReached

        var errorDescription: String? {
            switch self {
            case .realmSaveFailed: return "端末への保存に失敗しました"
            case .limitReached: return LocalizeKey.limitReachedMessage.localizedString()
            }
        }
    }

    @IBAction func tapDoneButton(_ sender: Any) {
        // UIKitの値はメインスレッドで読み取ってからTaskに渡す
        guard let sourceImage = choiceImage,
              let postImage = sourceImage.resize(size: convertedImageSize(size: sourceImage.size)) else {
            return
        }
        // 入口(FAB)でも見ているが、写真を選んでいる間に別経路で増える可能性があるため保存直前にも確かめる
        guard RealmManager.shared.canSaveMorePhotos else {
            showUploadError(UploadError.limitReached)
            return
        }
        let titleText = titleTextField.text ?? ""
        doneButton.isEnabled = false

        // 公開投稿を廃止したためサーバ通信は無く、端末内でIDを採番して保存するだけ
        guard saveRealm(id: UUID().uuidString, title: titleText, postedImage: postImage, isPublic: false) else {
            doneButton.isEnabled = true
            showUploadError(UploadError.realmSaveFailed)
            return
        }
        NotificationCenter.default.post(name: .finishUpload, object: nil, userInfo: nil)
        if GroupeDefaults.shared.isRateAlert() {
            requestReview()
        }
        dismiss(animated: true, completion: nil)
    }

    private func requestReview() {
        guard let scene = view.window?.windowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
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
                                    // ownerId は見本画像の判定("official")にしか使っていない。
                                    // 利用者の画像は端末内にしか無いため所有者の概念が要らない
                                    ownerId: "")
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

extension AddViewController: UITextFieldDelegate {
    //テキストフィールドでリターンが押されたときに通知され起動するメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //textField.resignFirstResponder()　←↓どっちでもいい
        self.view.endEditing(true)
        return true
    }
}
