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
import ENSwiftSideMenu
import FontAwesome_swift
import Floaty

class MainTabViewController: TabmanViewController, FloatyDelegate {

    lazy var viewControllers: [UIViewController] = {
        var viewControllers = [UIViewController]()
        for _ in 0 ..< 5 {
            viewControllers.append(makeChildViewController())
        }
        return viewControllers
    }()
    
    @IBOutlet weak var barMenuButton: UIBarButtonItem!
    
    var floaty = Floaty()
//    private var viewControllers = [ChildContentViewController(), ChildContentViewController()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        
        // Create bar
        let bar = TMBar.ButtonBar()
        bar.layout.transitionStyle = .snap // Customize
        
        // Add to view
        addBar(bar, dataSource: self, at: .top)
        
        let attributes = [NSAttributedString.Key.font: UIFont.fontAwesome(ofSize: 20, style: .brands)]
        barMenuButton.setTitleTextAttributes(attributes, for: .normal)
        barMenuButton.title = String.fontAwesomeIcon(name: . bars)
        
        layoutFAB()
//        Floaty.global.button.addItem(title: "Hello, World!")
//        Floaty.global.show()
    }
    
    func makeChildViewController() -> ChildContentViewController {
        let storyboard = UIStoryboard(name: "ChildContent", bundle: .main)
        return storyboard.instantiateInitialViewController() as! ChildContentViewController
    }
    
    func layoutFAB() {
        floaty.buttonColor = .green
        floaty.plusColor = .red
        floaty.sticky = true
        floaty.hasShadow = true
        let cameraImage = UIImage.fontAwesomeIcon(name: .camera, style: .solid, textColor: .green, size: CGSize(width: 20, height: 20))
        floaty.addItem(icon: cameraImage) { (item) in
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self.present(picker, animated: true, completion: {
                    self.floaty.close()
                })
            } else {
                self.floaty.close()
            }
        }
        let photoImage = UIImage.fontAwesomeIcon(name: .images, style: .solid, textColor: .green, size: CGSize(width: 20, height: 20))
        floaty.addItem(icon: photoImage) { (item) in
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self.present(picker, animated: true, completion: {
                    self.floaty.close()
                })
            } else {
                self.floaty.close()
            }
        }
        self.view.addSubview(floaty)
    }
    
    // MARK: - Floaty Delegate Methods
    func floatyWillOpen(_ floaty: Floaty) {
        
        print("Floaty Will Open")
        let sb = UIStoryboard(name: "Add", bundle: .main)
        let vc = sb.instantiateInitialViewController() as! AddViewController
        present(vc, animated: true) {
        }
    }
    
    func floatyDidOpen(_ floaty: Floaty) {
        print("Floaty Did Open")
    }
    
    func floatyWillClose(_ floaty: Floaty) {
        print("Floaty Will Close")
    }
    
    func floatyDidClose(_ floaty: Floaty) {
        print("Floaty Did Close")
    }
    
    
    @IBAction func tapBarMenuButton(_ sender: Any) {
        toggleSideMenuView()
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
        
        //        print("didScrollToPageAtIndex: \(index)")
        
//        gradient?.gradientOffset = gradientOffset(for: CGFloat(index))
//        statusView.currentIndex = index
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
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let title = "Page \(index)"
        return TMBarItem(title: title)
    }
}

extension MainTabViewController: ENSideMenuDelegate {
    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
    }
    
    func sideMenuWillClose() {
        print("sideMenuWillClose")
    }
    
    func sideMenuShouldOpenSideMenu() -> Bool {
        print("sideMenuShouldOpenSideMenu")
        return true
    }
    
    func sideMenuDidClose() {
        print("sideMenuDidClose")
    }
    
    func sideMenuDidOpen() {
        print("sideMenuDidOpen")
    }
}

extension MainTabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 画像選択
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
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
