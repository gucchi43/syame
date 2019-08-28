//
//  ChildContentViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import SwiftDate
import DZNEmptyDataSet
import DynamicColor
import FontAwesome_swift
import Ballcap
import Firebase
import CHTCollectionViewWaterfallLayout

class ChildContentViewController: UIViewController, RealmManagerDelegate, CHTCollectionViewDelegateWaterfallLayout {
    
    enum chengeType {
        case update
        case delete
        case insert
        case move
    }
    
    struct CollectionViewContentChange {
        let type: chengeType
        let indexPath: IndexPath?
        let newIndexPath: IndexPath?
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
//    var firePhotos: [Document<FirePhoto>] = []
    var contentChanges: [CollectionViewContentChange] = []
    var currentGenreTag:GenreTagType!

    var realmPhotos = RealmManager.shared.realmData
    var firePhotos: DataSource<Document<FirePhoto>>?
    var cacheIdArray: [String]?
    
    var tabPageIndex: Int!
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        RealmManager.shared.delegate = self
        if let tabPageIndex = tabPageIndex {
            currentGenreTag = GenreTagType.getAllGenreTags()[tabPageIndex]
        } else {
            currentGenreTag = GenreTagType.getAllGenreTags()[0]
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtons(notification:)), name: .updateListButton, object: self)
        commonInit()
        emptyDataSetInit()
        if pageboyPageIndex != 0 {
            photosInit()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateIndexLabel()
        if pageboyPageIndex == 0 {
            collectionView.reloadData()
        }
    }
    
    @objc func updateButtons(notification: Notification) -> Void {
        print("呼び出し！")
    }
    
    func photosInit() {
        var currentDataSource: DataSource<Document<FirePhoto>>?
        switch currentGenreTag {
        case .none:
            return
        case .some(.myBoard):
            return
        case .some(.new):
            let option = DataSource<Document<FirePhoto>>.Option()
            option.sortClosure = { l, r in return l.createdAt > r.createdAt }
            currentDataSource = Document<FirePhoto>.order(by: "createdAt").limit(to: 50).dataSource(option:option)
        case .some(.popular):
            let option = DataSource<Document<FirePhoto>>.Option()
            option.sortClosure = { l, r in return l.data!.saveCount > r.data!.saveCount }
            currentDataSource = Document<FirePhoto>.order(by: "saveCount").limit(to: 50).dataSource(option:option)
        case .some(.humor), .some(.cool), .some(.cute), .some(.serious), .some(.other):
            let option = DataSource<Document<FirePhoto>>.Option()
            option.sortClosure = { l, r in return l.data!.title < r.data!.title }
            currentDataSource = Document<FirePhoto>.where("genre", isEqualTo: currentGenreTag.getKey()).order(by: "title").dataSource(option:option)

        }
        firePhotos = currentDataSource!
             .on({ (snapshot, changes) in
                guard let collectionView = self.collectionView else { return }
                switch changes {
                case .initial:
                    collectionView.reloadData {
                        self.cacheIdArray = self.firePhotos?.documents.map({$0.id})
                    }
                case .update(let deletions, let insertions, let modifications):
                    print("ジャンル : ", self.currentGenreTag.getKey())
                    print("deletions : ", deletions)
                    print("insertions : ", insertions)
                    print("modifications : ", modifications)
                    // 過去のdsと最新のdsの差分をmodificationsと合体させて、reloadItemsさせる
                    let newIdArray = self.firePhotos?.documents.map({$0.id})
                    var diffs: [Int] = []
                    if modifications.count > 0 {
                        if let cacheIdArray = self.cacheIdArray, let newIdArray = newIdArray {
                            diffs = cacheIdArray.enumerated().filter { $0.1 != newIdArray[$0.0] }.map { $0.0 }
                        }                        
                    }
                    diffs += modifications
                    let orderedSet: NSOrderedSet = NSOrderedSet(array: diffs)
                    diffs = orderedSet.array as! [Int]
                    print("diffs : ", diffs)
                    collectionView.performBatchUpdates({
                        collectionView.insertItems(at: insertions.map({ IndexPath(row: $0, section: 0)}))
                        collectionView.deleteItems(at: deletions.map({ IndexPath(row: $0, section: 0)}))
                        collectionView.reloadItems(at: diffs.map({ IndexPath(row: $0, section: 0)}))
                    }, completion: { (done) in
                        self.cacheIdArray = self.firePhotos?.documents.map({$0.id})
                    })
                case .error(let error):
                    print(error)
                }
        }).listen()
    }
    
    private func updateIndexLabel() {
        if let index = tabPageIndex {
            let isFirstPage = index == 0
            var prompt = "(Index \(index))"
            if isFirstPage {
                prompt.append("\n\nswipe me >")
            }
            print(prompt)
        }
    }
    
    func commonInit() {
        collectionView.dataSource = self
        collectionView.delegate = self
        setupCollectionView()
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.contentMode = .left
        collectionView.backgroundView?.backgroundColor = UIColor.bgDark().lighter(amount: 0.8)
        collectionView.backgroundColor = .bgDark()
        refreshControl.addTarget(self, action: #selector(self
            .refresh(sender:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        print("tabPageIndex : ", tabPageIndex)
    }
    
    //MARK: - CollectionView UI Setup
    func setupCollectionView(){
        
        // Create a waterfall layout
        let layout = CHTCollectionViewWaterfallLayout()
        
        // Change individual layout attributes for the spacing between cells
        layout.minimumColumnSpacing = 8.0
        layout.minimumInteritemSpacing = 8.0
        layout.sectionInset = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 88.0, right: 8.0)
        
        // Collection view attributes
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.alwaysBounceVertical = true
        
        // Add the waterfall layout to your collection view
        collectionView.collectionViewLayout = layout
    }
    
    func emptyDataSetInit(){
        collectionView.emptyDataSetDelegate = self
        collectionView.emptyDataSetSource = self
    }
    
    func realmObjectDidChange() {
        print("realm のなんかが変更された")
        NotificationCenter.default.post(name: .updateListButton, object: nil)
//        if let mTVC = pageboyParent as? MainTabViewController {
//            mTVC.allListButtonUpdate()
//        }
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        // refresh処理
        collectionView.reloadData {
            sender.endRefreshing()
        }
    }
    
    func checkSaved(index: Int) -> Bool {
        if tabPageIndex == 0 {
            return true
        } else {
            let currentFirePhoto = firePhotos![index]
            let selectSavedPhotos = realmPhotos?.filter { $0.id == currentFirePhoto.id}
            if selectSavedPhotos!.count > 0 {
                return true
            } else {
                return false
            }
        }
    }
    
    func updateSaveCount(doc: Document<FirePhoto>, up: Bool) {
        if up {
            doc.data!.saveCount += 1
        } else {
            if doc.data!.saveCount > 0 {
                doc.data!.saveCount -= 1
            }
        }
        
        doc.update { (error) in
            if let error = error {
                print(error)
            }
        }
    }

    @objc func tapCellSaveButton(sender: UIButton) {
        let cell = sender.superview?.superview?.superview as! PhotoCollectionViewCell
        let row = collectionView.indexPath(for: cell)!.row
        let index = row
        
        if checkSaved(index: index) {
            var id: String!
            if tabPageIndex == 0 {
                id = realmPhotos![index].id
            } else {
                id = firePhotos![index].id
            }
            // Realmからdeleteする
            RealmManager.shared.delete(docId: id, success: { () in
                if self.tabPageIndex == 0  {
                        Document<FirePhoto>.get(id: id) { (doc, error) in
                            guard let doc = doc else { return }
                            self.updateSaveCount(doc: doc, up: false)
                            // マイキーボードのみRealmなのでこちらでCell処理
                            self.contentChanges.append(CollectionViewContentChange(type: .delete, indexPath: IndexPath(row: index, section: 0), newIndexPath: nil))
                            self.batchUpdate()
                        }
                } else {
                    self.updateSaveCount(doc: self.firePhotos![index], up: false)
                }
            }) { (error) in
                print(error)
            }
        } else {
            
            if GroupeDefaults.shared.isAddCount() {
                return showAdd()
            }

            var photo = RealmPhoto()
            if tabPageIndex == 0 {
                photo = realmPhotos![index]
            } else {
                let selectData = firePhotos![index]
                guard let image = cell.photoImageView.image else { return }
                photo = RealmPhoto.create(id: selectData.id,
                                            text: selectData.data!.title,
                                            image: image,
                                            imageHeight: selectData.data!.imageHeight,
                                            imageWidth: selectData.data!.imageWidth,
                                            getDay: Date().toString())
            }
            
            // Realmにsaveする
            RealmManager.shared.save(data: photo, success: {() in
                if self.tabPageIndex == 0  {
                    self.updateSaveCount(doc: self.firePhotos![index], up: true)
                } else {
                    self.updateSaveCount(doc: self.firePhotos![index], up: true)
                }
                GroupeDefaults.shared.useSaveLife()
            }) { (error) in
                print(error)
            }
        }
    }
    
    func showAdd() {
        let alert = UIAlertController(title: "これ以上SAVEするには広告を見てね", message: "５枚画像を保存するごとにお願いしてるよ", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            // 広告流す
            print("call add")
            GroupeDefaults.shared.chargeSaveLife()
        })
        let cancell = UIAlertAction(title: "キャンセル", style: .default, handler: { (action) in
            print("cancell cell add")
        })
        alert.addAction(ok)
        alert.addAction(cancell)
        present(alert, animated: true) {
        }
    }
    
    func batchUpdate() {
        collectionView?.performBatchUpdates({
            for contentChange in self.contentChanges {
                print("contentChange.indexPath : ", contentChange.indexPath)
                switch contentChange.type {
                case .insert:
                    collectionView.insertItems(at: [contentChange.newIndexPath!])
                case .update:
                    collectionView.reloadItems(at: [contentChange.indexPath!])
                case .move:
                    collectionView?.moveItem(at: contentChange.indexPath!, to: contentChange.newIndexPath!)
                case .delete:
                    collectionView?.deleteItems(at: [contentChange.indexPath!])
                }
            }
        }, completion: { _ in
            self.contentChanges = [CollectionViewContentChange]()
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        var size: CGSize!
        if tabPageIndex == 0 {
            let w = realmPhotos![indexPath.row].imageWidth
            let h = realmPhotos![indexPath.row].imageHeight
            size = CGSize(width: w, height: h)
        } else {
            let w = firePhotos![indexPath.row].data!.imageWidth
            let h = firePhotos![indexPath.row].data!.imageHeight
            size = CGSize(width: w, height: h)
        }
        return convertBestSize(before: size)
    }
    
    private func convertBestSize(before: CGSize) -> CGSize {
        let w = before.width
        let h = before.height
        
        if w * 1.8 < h {
            return CGSize(width: w, height: h * 0.8)
        } else if w * 1.5 < h {
            return CGSize(width: w, height: h * 1.0)
        } else if w < h {
            return CGSize(width: w, height: h * 1.2)
        } else if w * 0.8 < h {
            return CGSize(width: w, height: h * 1.5)
        }else if w * 0.5 < h {
            return CGSize(width: w, height: h * 1.8)
        } else {
            return CGSize(width: w, height: h * 2.0)
        }
    }
}

extension ChildContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if tabPageIndex == 0 {
            guard let photos = realmPhotos else { return 0 }
            
            print("れるむの数 : ",photos.count)
            
            return photos.count
        } else {
            return firePhotos?.count ??  0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        if let cell = cell as? PhotoCollectionViewCell {
            
            if tabPageIndex == 0 {
                let photo = realmPhotos![indexPath.row]
                cell.configure(photo: photo, saved: true)
            } else {
                if self.checkSaved(index: indexPath.row) {
                    cell.configure(doc: firePhotos![indexPath.row], saved: true)
                } else {
                    cell.configure(doc: firePhotos![indexPath.row], saved: false)
                }
            }
            
            //  test
//            cell.titleLabel.text = "row : " + String(indexPath.row) +  ", section : " + String(indexPath.item)
//            print("firePhotos![indexPath.row].createdAt : ", firePhotos?[indexPath.row].createdAt ??  realmPhotos![indexPath.row].getDay)
//            if tabPageIndex != 0 {
//                cell.countNumLabel.text = firePhotos![indexPath.row].createdAt.dateValue().toString()
//            }
            
            cell.saveButton.tag = indexPath.row
            cell.saveButton.addTarget(self, action: #selector(self.tapCellSaveButton(sender: )), for: .touchUpInside)
        }
        return cell
    }
}

extension ChildContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        print("=========")
        print("call didDeselectItemAt")
        print("indexpath : ", indexPath)
        print("=========")
//        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
//            return //the cell is not visible
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("=========")
        print("call didSelectItemAt 解除モード")
        print("indexpath : ", indexPath)
        print("=========")
    }
    
    fileprivate func getModel(at indexPath: IndexPath) -> Document<FirePhoto>? {
        guard !self.firePhotos!.isEmpty && indexPath.row >= 0 && indexPath.row < self.firePhotos!.count else { return nil }
        return self.firePhotos![indexPath.row]
    }
}

extension ChildContentViewController {
    func performCollectionViewChange(_ contentChange: CollectionViewContentChange) {
        switch contentChange.type {
        case .insert:
            collectionView.insertItems(at: [contentChange.newIndexPath!])
        case .update:
            collectionView.reloadItems(at: [contentChange.indexPath!])
        case .move:
            collectionView?.moveItem(at: contentChange.indexPath!, to: contentChange.newIndexPath!)
        case .delete:
            collectionView?.deleteItems(at: [contentChange.indexPath!])
        }
    }
}

extension ChildContentViewController: DZNEmptyDataSetSource {
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return .bgDark()
    }
    
    /// データが空の状態の時に表示したい画像
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        let image = UIImage.fontAwesomeIcon(name: .grinTears, style: .solid, textColor: .acGreen(), size: CGSize(width: 80, height: 80))
        return  image
    }
    //
    /// データが空の状態の時に表示したい属性付きタイトル文字列
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let title = "カラッポ"
        let attributes: [NSAttributedString.Key: Any]
            = [.font: UIFont.boldSystemFont(ofSize: 19),
               .foregroundColor: UIColor.acGreen()]
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        let deviceHeight = UIScreen.main.bounds.size.height
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        guard let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height else { return 0.0 }
        let barHeight = deviceHeight - (collectionView.contentSize.height + statusBarHeight + navigationBarHeight)
        print("deviceHeight : ", deviceHeight)
        print("collectionView.contentSize.height : ", collectionView.frame.size.height)
        print("statusBarHeight : ", statusBarHeight)
        print("navigationBarHeight : ", navigationBarHeight)
        print("self.view.frame.size.height : ", self.view.frame.size.height)
        print("barHeight : ", barHeight)
        //        let navigationBarHeight = self.navigationController!.navigationBar.frame.size.height
        
        
        return -navigationBarHeight*2
    }
}

/// データが空の状態の時に表示したい属性付き説明文字列
//    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
//        let text = """
//        まだマイキーボードに何も登録できてないよ
//        正直やばいよ、君だけだよ
//        まずは「人気」欄から登録してみよう！
//        """
//
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.alignment = .natural
//        paragraphStyle.lineBreakMode = .byWordWrapping
//        let attributes: [NSAttributedString.Key: Any]
//            = [.font: UIFont.boldSystemFont(ofSize: 19),
//               .foregroundColor: UIColor..acGreen(),
//               .paragraphStyle: paragraphStyle]
//
//        return NSAttributedString(string: text, attributes: attributes)
//    }

extension ChildContentViewController: DZNEmptyDataSetDelegate {
    /// EmptyDataSetViewがタップされた時の動作
    func emptyDataSet(_ scrollView: UIScrollView!, didTap view: UIView!) {
        // 何かの動作
    }
}
