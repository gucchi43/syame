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
import Firebase
import FirebaseFirestoreSwift
import Realm
import RealmSwift
import CHTCollectionViewWaterfallLayout
import GoogleMobileAds

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
    var contentChanges: [CollectionViewContentChange] = []
    var currentGenreTag:GenreTagType!
    var realmPhotos: Results<RealmPhoto>?
    var tabPageIndex: Int!
    private let refreshControl = UIRefreshControl()
    #if DEBUG
    let addId = "ca-app-pub-3940256099942544/1712485313"
    #else
    let addId = "ca-app-pub-2311091333372031/6162073771"
    #endif
    private var firePhotoCollection : CollectionReference = RootStore.rootDB().collection("ofirephoto")
    private var oFirePhotos : [OFirePhoto] = []
    private var lastDoc: DocumentSnapshot?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realmPhotos = RealmManager.shared.realmData
        RealmManager.shared.delegate = self
        if let tabPageIndex = tabPageIndex {
            currentGenreTag = GenreTagType.getAllGenreTags()[tabPageIndex]
        } else {
            currentGenreTag = GenreTagType.getAllGenreTags()[0]
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSaveState(notification:)), name: .updateSaveState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAfterPost(notification:)), name: .allRelaod, object: nil)
        commonInit()
        emptyDataSetInit()
        if pageboyPageIndex != 0 {
            firePhotoInit()
        }
        setUpAd()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateIndexLabel()
        if pageboyPageIndex == 0 {
            collectionView.reloadData()
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
    
    func createQuery(lastDoc: DocumentSnapshot? = nil) -> Query? {
        var query: Query?
        switch currentGenreTag {
        case .none:
            query = nil
        case .some(.myBoard):
            query = nil
        case .some(.new):
            if let lastDoc = lastDoc {
                query = firePhotoCollection
                    .order(by: "createdAt", descending: true)
                    .limit(to: 20)
                    .start(afterDocument: lastDoc)
            } else {
                query = firePhotoCollection
                    .order(by: "createdAt", descending: true)
                    .limit(to: 20)
            }
        case .some(.popular):
            let sevenBeforeDay = Date()-7.days
            let sevenBeforeTimeStamp = Timestamp(date: sevenBeforeDay.date)
            if let lastDoc = lastDoc {
                query = firePhotoCollection
                    .whereField("updateAt", isGreaterThan: sevenBeforeTimeStamp)
                    .order(by: "updateAt")
                    .order(by: "weeklySaveCount")
                    .limit(to: 20)
                    .start(afterDocument: lastDoc)
            } else {
                query = firePhotoCollection
                    .whereField("updateAt", isGreaterThan: sevenBeforeTimeStamp)
                    .order(by: "updateAt")
                    .order(by: "weeklySaveCount")
                    .limit(to: 20)
            }
        case .some(.humor), .some(.cool), .some(.cute), .some(.serious), .some(.other):
            if let lastDoc = lastDoc {
                query = firePhotoCollection
                    .whereField("genre", isEqualTo: currentGenreTag.getKey())
                    .order(by: "title")
                    .limit(to: 20)
                    .start(afterDocument: lastDoc)
            } else {
                query = firePhotoCollection
                    .whereField("genre", isEqualTo: currentGenreTag.getKey())
                    .order(by: "title")
                    .limit(to: 20)
            }
        }
        return query
    }
    
    func firePhotoInit() {
        guard let currentQuery = createQuery() else { return }
        currentQuery.getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            if let error = error {
                print("Error retreiving collection: \(error)")
                return
            }
            
            print("snapshot : ", snapshot)
            print("snapshot.documents : ", snapshot.documents)
            
            if let lastDoc = snapshot.documents.last {
                self.lastDoc = lastDoc
            } else {
                self.lastDoc = nil
            }
            let decoder = Firestore.Decoder()
            let newFirePhotos = snapshot.documents.map{ oFirePhoto -> OFirePhoto in
                let data = oFirePhoto.data()
                    var model = try! decoder.decode(OFirePhoto.self, from: data)
                return model
            }
            self.oFirePhotos = newFirePhotos
            print("self.oFirePhotos : ", self.oFirePhotos)
            guard let collectionView = self.collectionView else { return }
            collectionView.reloadData()
        }
    }
    
    func nextLoad() {
        guard let lastDoc = lastDoc else {
            print("not next data")
            return
        }
        guard let currentQuery = createQuery(lastDoc: lastDoc) else { return }
        currentQuery.getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            if let error = error {
                print("Error retreiving collection: \(error)")
                return
            }
            if let lastDoc = snapshot.documents.last {
                self.lastDoc = lastDoc
            } else {
                self.lastDoc = nil
            }
            // モデルに当て込み
            let decoder = Firestore.Decoder()
            let newFirePhotos = snapshot.documents.map{ oFirePhoto -> OFirePhoto in
                let data = oFirePhoto.data()
                var model = try! decoder.decode(OFirePhoto.self, from: data)
                model.id = oFirePhoto.documentID
                return model
            }
            self.oFirePhotos += newFirePhotos
            guard let collectionView = self.collectionView else { return }
            collectionView.reloadData()
        }
    }
    
    @objc func reloadAfterPost(notification: Notification) -> Void {
        if pageboyPageIndex == 0 {
            print("realmPhotos :", realmPhotos)
            collectionView.reloadData()
        } else {
            firePhotoInit()
        }
    }
    
    @objc func reloadSaveState(notification: Notification) -> Void {
        if let info = notification.userInfo {
            let id = info["id"] as! String
            let saveFlag = info["saveFlag"] as! Bool
            print("ジャンル : ", self.currentGenreTag.getKey(), "チェンジ！")
            print("changeするId", id)
            print("changeするsaveFlag", saveFlag)
            var changeIndex: [IndexPath]
            if pageboyPageIndex == 0 {
                print("realmPhotos :", realmPhotos)
                return collectionView.reloadData()
            } else {
                changeIndex = oFirePhotos.enumerated().filter{ $0.1.id == id }.map { IndexPath(row: $0.0, section: 0) }
            }
            print("changeIndex: ", changeIndex)
            if let indexPath = changeIndex.first {
                if pageboyPageIndex == 0 {
                    if saveFlag {
                        self.contentChanges.append(CollectionViewContentChange(type: .insert, indexPath: indexPath, newIndexPath: nil))
                    } else {
                        self.contentChanges.append(CollectionViewContentChange(type: .delete, indexPath: indexPath, newIndexPath: nil))
                    }
                } else {
                    self.contentChanges.append(CollectionViewContentChange(type: .update, indexPath: indexPath, newIndexPath: nil))
                }
                self.batchUpdate()
            }
        }
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
    
    func realmObjectDidChange() {
        print("realm のなんかが変更された ジャンル : ", currentGenreTag.getKey())
//        NotificationCenter.default.post(name: .updateSaveState, object: nil)
//        let mTVC = MainTabViewController()
//        mTVC.allListButtonUpdate()
//        self.reloadSaveState()
        
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        // refresh処理
        if tabPageIndex == 0 {
            return collectionView.reloadData {
                sender.endRefreshing()
            }
        }
        guard let currentQuery = createQuery() else { return }
        currentQuery.getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            if let error = error {
                print("Error retreiving collection: \(error)")
                return
            }
            if let lastDoc = snapshot.documents.last {
                self.lastDoc = lastDoc
            } else {
                self.lastDoc = nil
            }
            let decoder = Firestore.Decoder()
            self.oFirePhotos = snapshot.documents.map{ oFirePhoto -> OFirePhoto in
                let data = oFirePhoto.data()
                var model = try! decoder.decode(OFirePhoto.self, from: data)
                model.id = oFirePhoto.documentID
                print("model : ", model)
                return model
            }
            print("self.oFirePhotos : ", self.oFirePhotos)
            guard let collectionView = self.collectionView else { return }
            collectionView.reloadData {
                sender.endRefreshing()
            }
        }
    }
    
    func checkSaved(index: Int) -> Bool {
        if tabPageIndex == 0 {
            return true
        } else {
            let currentFirePhoto = oFirePhotos[index]
            print("currentFirePhoto.id : ", currentFirePhoto.id)
            let selectSavedPhotos = realmPhotos?.filter { $0.id == currentFirePhoto.id}
            if selectSavedPhotos!.count > 0 {
                return true
            } else {
                return false
            }
        }
    }
    
    func updateSaveCount(doc: OFirePhoto, up: Bool) {
        let beforeStartDay = doc.weekStartDay
        let currentStartDay = Date().dateAt(.startOfWeek).toString()
        var updateDoc = doc
        if beforeStartDay != currentStartDay {
            updateDoc.weeklySaveCount = 0
            updateDoc.weekStartDay = currentStartDay
        }
        print("baforeStartDay : ", beforeStartDay)
        print("currentStartDay : ", currentStartDay)
        if up {
            updateDoc.totalSaveCount += 1
            updateDoc.weeklySaveCount += 1
        } else {
            if doc.totalSaveCount > 0 {
                updateDoc.totalSaveCount -= 1
            }
            if doc.weeklySaveCount > 0 {
                updateDoc.weeklySaveCount -= 1
            }
        }
        updateDoc.updateAt = Timestamp(date: Date())
        let encoder = Firestore.Encoder()
        let updatePhotoDoc = try! encoder.encode(updateDoc)
        firePhotoCollection.document(doc.id).setData(updatePhotoDoc, merge: true) { (error) in
            if let error = error {
                print(error)
            } else {
                print("savecont update success")
            }
        }
    }
    
    @objc func tapCellSaveButton(sender: UIButton) {
        let cell = sender.superview?.superview?.superview as! PhotoCollectionViewCell
        let row = collectionView.indexPath(for: cell)!.row
        let index = row
        
        var id: String!
        if tabPageIndex == 0 {
            id = realmPhotos![index].id
        } else {
            id = oFirePhotos[index].id
        }
        
        if checkSaved(index: index) {
            // Realmからdeleteする
            // チュートリアルの時に入れていた画像のため例外処理
            var tutorialDataFlag: Bool!
            if self.realmPhotos![index].ownerId == "official" {
                tutorialDataFlag = true
            } else {
                tutorialDataFlag = false
            }
            RealmManager.shared.delete(docId: id, success: { () in
                NotificationCenter.default.post(name: .updateSaveState, object: nil, userInfo: ["id": id!, "saveFlag": false])
                if self.tabPageIndex == 0  {
                    if tutorialDataFlag == true {
                        return
                    }
                    self.firePhotoCollection.document(id).getDocument(completion: { (snapshot, error) in
                        guard let snapshot = snapshot else { return }
                        let decoder = Firestore.Decoder()
                        let updatePhotoDoc = try! decoder.decode(OFirePhoto.self, from: snapshot.data()!)
                        self.updateSaveCount(doc: updatePhotoDoc, up: false)
                    })
                } else {
                    self.updateSaveCount(doc: self.oFirePhotos[index], up: false)
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
                let selectData = oFirePhotos[index]
                guard let image = cell.photoImageView.image else { return }
                print("selectData.id : ", selectData.id)
                photo = RealmPhoto.create(id: selectData.id,
                                            text: selectData.title,
                                            image: image,
                                            imageHeight: selectData.imageHeight,
                                            imageWidth: selectData.imageWidth,
                                            getDay: Date().toString(),
                                            isPublic: true,
                                            ownerId: selectData.ownerId!)
            }
            // Realmにsaveする
            RealmManager.shared.save(data: photo, success: {() in
                NotificationCenter.default.post(name: .updateSaveState, object: nil, userInfo: ["id": id!, "saveFlag": true])
                if self.tabPageIndex == 0  {
                    self.updateSaveCount(doc: self.oFirePhotos[index], up: true)
                } else {
                    self.updateSaveCount(doc: self.oFirePhotos[index], up: true)
                }
                GroupeDefaults.shared.useSaveLife()
                if GroupeDefaults.shared.isRateAlert() {
                    SKStoreReviewController.requestReview()
                }
            }) { (error) in
                print(error)
            }
        }
    }
    
    func showAdd() {
        let alert = UIAlertController(title:LocalizeKey.adAlertTitle.localizedString(), message: LocalizeKey.adAlertTitle.localizedString(), preferredStyle: .alert)
        let ok = UIAlertAction(title: LocalizeKey.baseOK.localizedString(), style: .default, handler: { (action) in
            // 広告流す
            print("call add")
            GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
            
//            if self.rewardedAd?.isReady == true {
//                GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
////                self.rewardedAd?.present(fromRootViewController: self, delegate:self)
//            } else {
//                UIAlertView(title: "Rewarded video not ready",
//                            message: "The rewarded video didn't finish loading or failed to load",
//                            delegate: self,
//                            cancelButtonTitle: "Drat").show()
//            }
            
//            GroupeDefaults.shared.chargeSaveLife()
        })
        let cancell = UIAlertAction(title: LocalizeKey.baseCancel.localizedString(), style: .default, handler: { (action) in
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
            let w = oFirePhotos[indexPath.row].imageWidth
            let h = oFirePhotos[indexPath.row].imageHeight
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
    
    func goPotoDetail(rPhoto: RealmPhoto?, fPhoto: OFirePhoto?) {
        let sb = UIStoryboard(name: "PhotoDetail",bundle: nil)
        let vc = sb.instantiateInitialViewController() as! PhotoDetailViewController
        vc.rPhoto = rPhoto
        vc.fPhoto = fPhoto
        present(vc, animated: true, completion: nil)
    }
}

extension ChildContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if tabPageIndex == 0 {
            guard let photos = realmPhotos else { return 0 }
            
            print("れるむの数 : ",photos.count)
            
            return photos.count
        } else {
            return oFirePhotos.count
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
                    cell.configure(doc: oFirePhotos[indexPath.row], saved: true)
                } else {
                    cell.configure(doc: oFirePhotos[indexPath.row], saved: false)
                }
            }
            cell.saveButton.tag = indexPath.row
            cell.saveButton.addTarget(self, action: #selector(self.tapCellSaveButton(sender: )), for: .touchUpInside)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath == collectionView.indexPathForLastItem {
            print("last cell -> call next")
            self.nextLoad()
        }
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
        if tabPageIndex == 0 {
            goPotoDetail(rPhoto: realmPhotos![indexPath.row], fPhoto: nil)
        } else {
            goPotoDetail(rPhoto: nil, fPhoto: oFirePhotos[indexPath.row])
        }
        
    }
    
    fileprivate func getModel(at indexPath: IndexPath) -> OFirePhoto? {
        guard !self.oFirePhotos.isEmpty && indexPath.row >= 0 && indexPath.row < self.oFirePhotos.count else { return nil }
        return self.oFirePhotos[indexPath.row]
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
        var title = LocalizeKey.othersEmptyTitle.localizedString()
        if pageboyPageIndex == 0 {
            title = LocalizeKey.myBoardEmptyTitle.localizedString()
        }
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

extension ChildContentViewController: GADRewardBasedVideoAdDelegate {
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("Reward received with currency: \(reward.type), amount \(reward.amount).")
        GroupeDefaults.shared.chargeSaveLife(amount: Int(truncating: reward.amount))
    }
    
    func setUpAd() {
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(),
                                                    withAdUnitID: addId)
    }
    
    func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
        print("Rewarded ad presented.")
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        print("Rewarded ad dismissed.")
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(),
                                                    withAdUnitID: addId)
    }
}
