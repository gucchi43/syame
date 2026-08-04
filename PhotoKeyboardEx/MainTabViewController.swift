//
//  MainTabViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import Toast

/// アプリのメイン画面。
/// 公開フィードを廃止したため、表示するのは「マイボード」の1画面のみ。
/// 以前は Tabman + Pageboy で8タブを切り替えていたが、タブが1つになったため両ライブラリを外した。
class MainTabViewController: UIViewController {

    @IBOutlet weak var barMenuButton: UIBarButtonItem!

    var fabButton = UIButton(type: .custom)

    private lazy var boardViewController: ChildContentViewController = {
        let storyboard = UIStoryboard(name: "ChildContent", bundle: .main)
        return storyboard.instantiateInitialViewController() as! ChildContentViewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }

    func commonInit() {
        view.backgroundColor = .bgBase
        navigationItem.title = LocalizeKey.navMyBoard.localizedString()

        barMenuButton.applySymbol(Symbol.menu)

        embedBoardViewController()
        layoutFAB()
        NotificationCenter.default.addObserver(self, selector: #selector(finishToast(notification:)), name: .finishUpload, object: nil)
    }

    /// 一覧を子ViewControllerとして敷く。FABは後から載せるため一覧より前面に来る。
    private func embedBoardViewController() {
        let child = boardViewController
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        child.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // viewWillAppear での present は遷移中に失敗するため viewDidAppear で行う
        presentOnboardingIfNeeded()
    }

    /// 起動時に出すのは Top だけにする。
    ///
    /// 以前はこの直後にキーボード設定の案内を挟んでいたが、
    /// フルアクセスという重い許可を、価値を体験する前に要求する構造になっていた。
    /// 設定の案内は最初の1枚を保存したあとに出す(showKeyboardSetupIfNeeded)。
    private func presentOnboardingIfNeeded() {
        guard presentedViewController == nil else { return }
        guard GroupeDefaults.shared.isRegisterPush() else { return }
        seedTutorialPhotoIfNeeded()
        guard let vc = UIStoryboard(name: "Top", bundle: nil).instantiateInitialViewController() else { return }
        present(vc, animated: false, completion: nil)
    }

    /// 見本の画像を1枚入れておく。
    /// 以前はキーボード設定画面の表示時に投入していたため、
    /// その画面を出さなくなるとボードが空のままになる。
    private func seedTutorialPhotoIfNeeded() {
        guard let photo = makeOfficialPhoto() else { return }
        let alreadySeeded = RealmManager.shared.realmData.contains { $0.id == photo.id }
        guard !alreadySeeded else { return }
        RealmManager.shared.save(data: photo, success: {}, failure: { error in print(error) })
    }

    /// 最初の1枚が保存できたところでキーボード設定を案内する。
    /// 保存するものができて初めてキーボードが役に立つため、この順序にしている。
    private func showKeyboardSetupIfNeeded() {
        guard presentedViewController == nil else { return }
        guard GroupeDefaults.shared.isUsagePush() else { return }
        guard let nvc = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController() else { return }
        present(nvc, animated: true, completion: nil)
    }

    @objc func finishToast(notification: Notification) {
        var style = ToastStyle()
        style.messageColor = .onAccent
        style.backgroundColor = .accent
        style.cornerRadius = 20.0
        style.horizontalPadding = 20.0
        self.view.makeToast(LocalizeKey.doneUploadToast.localizedString(), duration: 3.0, position: .top, style: style)
        NotificationCenter.default.post(name: .allReload, object: nil, userInfo: nil)
        // トーストと重ならないよう、表示が落ち着いてから案内する
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.showKeyboardSetupIfNeeded()
        }
    }

    func layoutFAB() {
        let size: CGFloat = 56
        fabButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        fabButton.backgroundColor = .accent
        fabButton.applyCornerRadius(size / 2)
        fabButton.layer.shadowColor = UIColor.black.cgColor
        fabButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        fabButton.layer.shadowOpacity = 0.3
        fabButton.layer.shadowRadius = 4
        fabButton.setImage(.symbol(Symbol.add, pointSize: 22, weight: .medium), for: .normal)
        fabButton.tintColor = .onAccent
        fabButton.addTarget(self, action: #selector(tapFAB), for: .touchUpInside)
        fabButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fabButton)
        NSLayoutConstraint.activate([
            fabButton.widthAnchor.constraint(equalToConstant: size),
            fabButton.heightAnchor.constraint(equalToConstant: size),
            fabButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    @objc func tapFAB() {
        // 画像を選んでから投稿画面へ進む。画像未選択のままでは完了ボタンが有効にならない。
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func tapBarMenuButton(_ sender: Any) {
        (navigationController as? MainNavigationViewController)?.toggleSideMenu()
    }
}

extension MainTabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // 画像選択
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        // dismissの完了を待たずにpresentすると遷移が失敗するため完了ハンドラで繋ぐ
        picker.dismiss(animated: true) { [weak self] in
            self?.presentAddViewController(with: image)
        }
    }

    private func presentAddViewController(with image: UIImage) {
        let sb = UIStoryboard(name: "Add", bundle: .main)
        guard let nvc = sb.instantiateInitialViewController() as? UINavigationController,
              let vc = nvc.viewControllers.first as? AddViewController else { return }
        vc.choiceImage = image
        present(nvc, animated: true)
    }

    //キャンセル
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
