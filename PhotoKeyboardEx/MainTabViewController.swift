//
//  MainTabViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import Tabman
import Pageboy
import PhotoKeyboardFramework
import Realm
import RealmSwift
import Toast

struct TabHead {
    let title: String
    let imageText: String
    let badge: String?
}

class MainTabViewController: TabmanViewController {
    var tabHeads = GenreTagType.getAllGenreTags()
    var titles = [LocalizeKey.navMyBoard.localizedString(),
                  LocalizeKey.navNew.localizedString(),
                  LocalizeKey.navPopular.localizedString(),
                  LocalizeKey.navHumor.localizedString(),
                  LocalizeKey.navCool.localizedString(),
                  LocalizeKey.navCute.localizedString(),
                  LocalizeKey.navSerious.localizedString(),
                  LocalizeKey.navOther.localizedString()]
    lazy var viewControllers: [UIViewController] = {
        var viewControllers = [UIViewController]()
        for _ in 0 ..< 8 {
            viewControllers.append(makeChildViewController())
        }
        return viewControllers
    }()
    
    @IBOutlet weak var barMenuButton: UIBarButtonItem!
    
    var firstFlag = true
    
    var fabButton = UIButton(type: .custom)
    
    let bar = TMBar.TabBar()
//    let bar = TMBar.ButtonBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }

    func commonInit() {
        self.dataSource = self
        self.view.backgroundColor = .bgDark()
        bar.tintColor = .acGreen()
        bar.backgroundColor = .bgDark()
        bar.backgroundView.style = .clear
        bar.layout.transitionStyle = .snap
        addBar(bar, dataSource: self, at: .top)
        
        barMenuButton.title = String.fontAwesomeIcon(name: .bars)
        barMenuButton.setTitleTextAttributes([.font: UIFont.fontAwesome(ofSize: 24, style: .solid)], for: .normal)
        
        if let pageboyPageIndex = pageboyPageIndex {
            self.navigationItem.title = titles[pageboyPageIndex]
        } else {
            self.navigationItem.title = titles.first
        }
        layoutFAB()
        NotificationCenter.default.addObserver(self, selector: #selector(finishToast(notification:)), name: .finishUpload, object: nil)
    }
        
    override func viewWillAppear(_ animated: Bool) {
        bar.buttons.customize { (button) in
            button.selectedTintColor = .acGreen()
            button.tintColor = .white
        }

        if GroupeDefaults.shared.isRegisterPush() {
            let vc = UIStoryboard(name: "Top",bundle: nil).instantiateInitialViewController() as! TopViewController
            present(vc, animated: false, completion: nil)
        } else if GroupeDefaults.shared.isUsagePush() {
            let sb = UIStoryboard(name: "Usage",bundle: nil)
            let nvc = sb.instantiateInitialViewController() as! UINavigationController
            present(nvc, animated: true, completion: nil)
        } else if GroupeDefaults.shared.isWelcomePush() {
            let sb = UIStoryboard(name: "Welcome",bundle: nil)
            let nvc = sb.instantiateInitialViewController() as! UINavigationController
            present(nvc, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func finishToast(notification: Notification) {
        // toast with a specific duration and position
        // create a new style
        var style = ToastStyle()
        style.messageColor = .white
        style.backgroundColor = UIColor.acGreen()
        style.cornerRadius = 20.0
        style.horizontalPadding = 20.0
        self.view.makeToast(LocalizeKey.doneUploadToast.localizedString(), duration: 3.0, position: .top, style: style)
        NotificationCenter.default.post(name: .allRelaod, object: nil, userInfo: nil)
    }
        
    func makeChildViewController() -> ChildContentViewController {
        let storyboard = UIStoryboard(name: "ChildContent", bundle: .main)
        return storyboard.instantiateInitialViewController() as! ChildContentViewController
    }
    
    func layoutFAB() {
        let size: CGFloat = 56
        fabButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        fabButton.backgroundColor = .acGreen()
        fabButton.layer.cornerRadius = size / 2
        fabButton.layer.shadowColor = UIColor.black.cgColor
        fabButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        fabButton.layer.shadowOpacity = 0.3
        fabButton.layer.shadowRadius = 4
        fabButton.setTitle("+", for: .normal)
        fabButton.setTitleColor(.white, for: .normal)
        fabButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .light)
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
        let sb = UIStoryboard(name: "Add", bundle: .main)
        let vc = sb.instantiateInitialViewController() as! AddViewController
        present(vc, animated: true)
    }
    
    
    @IBAction func tapBarMenuButton(_ sender: Any) {
        (navigationController as? MainNavigationViewController)?.toggleSideMenu()
    }
    
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        willScrollToPageAt index: PageboyViewController.PageIndex,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    willScrollToPageAt: index,
                                    direction: direction,
                                    animated: animated)
        //        print("willScrollToPageAtIndex: \(index)")
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didScrollTo position: CGPoint,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    didScrollTo: position,
                                    direction: direction,
                                    animated: animated)
        //        print("didScrollToPosition: \(position)")
        
        let relativePosition = navigationOrientation == .vertical ? position.y : position.x
//        gradient?.gradientOffset = gradientOffset(for: relativePosition)
//        statusView.currentPosition = relativePosition
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didScrollToPageAt index: PageboyViewController.PageIndex,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    didScrollToPageAt: index,
                                    direction: direction,
                                    animated: animated)
        
        print("didScrollToPageAtIndex: \(index)")
        self.navigationItem.title = titles[index]
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didReloadWith currentViewController: UIViewController,
                                        currentPageIndex: PageIndex) {
        super.pageboyViewController(pageboyViewController,
                                    didReloadWith: currentViewController,
                                    currentPageIndex: currentPageIndex)
    }
}

extension MainTabViewController: PageboyViewControllerDataSource, TMBarDataSource {
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController,
                        at index: PageboyViewController.PageIndex) -> UIViewController? {
        let vc = viewControllers[index] as! ChildContentViewController
        vc.tabPageIndex = index
        return vc
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .at(index: 1)
    }
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let curretTabHead = tabHeads[index]
        let title = curretTabHead.getLocalizeString()
        let emojiLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        emojiLabel.text = curretTabHead.getEmoji()
        let image = UIImage.imageWithLabel(emojiLabel)
        // TODO: 今後つけるかも
//        let badge = nil
        let item = TMBarItem(title: title, image: image, badgeValue: nil)
        return item
    }
}


extension MainTabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 画像選択
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        
        // カメラロールに保存する
        // UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.dismiss(animated: true)
        
        let sb = UIStoryboard(name: "Add", bundle: nil)
        let nvc = sb.instantiateInitialViewController() as! UINavigationController
        let vc = nvc.viewControllers.first as! AddViewController
        vc.choiceImage = image
        present(nvc, animated: true) {
            
        }
    }
    //キャンセル
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
