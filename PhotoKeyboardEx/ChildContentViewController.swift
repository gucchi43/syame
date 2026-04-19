//
//  ChildContentViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import StoreKit
import PhotoKeyboardFramework
import SwiftDate
import DynamicColor
import Realm
import RealmSwift
import GoogleMobileAds

class ChildContentViewController: UIViewController, RealmManagerDelegate {
    
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
    private let supabase = SupabaseManager.shared
    private var oFirePhotos : [OFirePhoto] = []
    private var currentOffset: Int = 0
    
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
            updateEmptyState()
        } else {
            let blockIncludes = self.mutedArray(origin: self.oFirePhotos)
            let blockIncludeIds = blockIncludes.map { $0.id }
            let currntIds = self.oFirePhotos.map { $0.id }
            if currntIds != blockIncludeIds {
                oFirePhotos = blockIncludes
                guard let collectionView = self.collectionView else { return }
                collectionView.reloadData()
            }
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
        let layout = createWaterfallLayout()
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.alwaysBounceVertical = true
        collectionView.collectionViewLayout = layout
    }

    private func createWaterfallLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .estimated(200)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(8.0)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8.0
            section.contentInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 8.0, bottom: 88.0, trailing: 8.0)
            return section
        }
        return layout
    }
    
    func updateEmptyState() {
        let itemCount: Int
        if tabPageIndex == 0 {
            itemCount = realmPhotos?.count ?? 0
        } else {
            itemCount = oFirePhotos.count
        }

        if itemCount == 0 {
            let emptyView = UIView(frame: collectionView.bounds)
            emptyView.backgroundColor = .bgDark()

            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 16
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let imageView = UIImageView()
            imageView.image = UIImage.fontAwesomeIcon(name: .grinTears, style: .solid, textColor: .acGreen(), size: CGSize(width: 80, height: 80))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true

            let titleLabel = UILabel()
            var title = LocalizeKey.othersEmptyTitle.localizedString()
            if pageboyPageIndex == 0 {
                title = LocalizeKey.myBoardEmptyTitle.localizedString()
            }
            titleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 19),
                    .foregroundColor: UIColor.acGreen()
                ]
            )
            titleLabel.textAlignment = .center

            stackView.addArrangedSubview(imageView)
            stackView.addArrangedSubview(titleLabel)
            emptyView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -60)
            ])

            collectionView.backgroundView = emptyView
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    func fetchPhotos(offset: Int = 0) async throws -> [OFirePhoto] {
        let client = supabase.client

        switch currentGenreTag {
        case .none, .some(.myBoard):
            return []
        case .some(.new):
            return try await client.from("photos")
                .select()
                .eq("locale", value: supabase.locale)
                .eq("is_debug", value: supabase.isDebug)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + 19)
                .execute()
                .value
        case .some(.popular):
            let sevenDaysAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7 * 24 * 60 * 60))
            return try await client.from("photos")
                .select()
                .eq("locale", value: supabase.locale)
                .eq("is_debug", value: supabase.isDebug)
                .gt("updated_at", value: sevenDaysAgo)
                .order("weekly_save_count", ascending: false)
                .range(from: offset, to: offset + 19)
                .execute()
                .value
        case .some(.humor), .some(.cool), .some(.cute), .some(.serious), .some(.other):
            return try await client.from("photos")
                .select()
                .eq("locale", value: supabase.locale)
                .eq("is_debug", value: supabase.isDebug)
                .eq("genre", value: currentGenreTag.getKey())
                .order("title")
                .range(from: offset, to: offset + 19)
                .execute()
                .value
        }
    }

    func firePhotoInit() {
        currentOffset = 0
        Task {
            do {
                let photos = try await fetchPhotos()
                self.oFirePhotos = self.mutedArray(origin: photos)
                self.currentOffset = photos.count
                guard let collectionView = self.collectionView else { return }
                await MainActor.run {
                    collectionView.reloadData()
                }
            } catch {
                print("Error fetching photos: \(error)")
            }
        }
    }
    
    func mutedArray(origin: [OFirePhoto]) -> [OFirePhoto] {
        let blockArray = GroupeDefaults.shared.getBlockContens()
        let newArray = origin.filter { (model) -> Bool in
            return !blockArray.contains(model.id.uuidString)
        }
        return newArray
    }
    
    func nextLoad() {
        Task {
            do {
                let photos = try await fetchPhotos(offset: currentOffset)
                guard !photos.isEmpty else { return }
                self.oFirePhotos += self.mutedArray(origin: photos)
                self.currentOffset += photos.count
                guard let collectionView = self.collectionView else { return }
                await MainActor.run {
                    collectionView.reloadData()
                }
            } catch {
                print("Error loading next: \(error)")
            }
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
                changeIndex = oFirePhotos.enumerated().filter{ $0.1.id.uuidString == id }.map { IndexPath(row: $0.0, section: 0) }
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
        if tabPageIndex == 0 {
            return collectionView.reloadData {
                sender.endRefreshing()
            }
        }
        currentOffset = 0
        Task {
            do {
                let photos = try await fetchPhotos()
                self.oFirePhotos = self.mutedArray(origin: photos)
                self.currentOffset = photos.count
                guard let collectionView = self.collectionView else { return }
                await MainActor.run {
                    collectionView.reloadData {
                        sender.endRefreshing()
                    }
                }
            } catch {
                print("Error refreshing: \(error)")
                await MainActor.run { sender.endRefreshing() }
            }
        }
    }
    
    func checkSaved(index: Int) -> Bool {
        if tabPageIndex == 0 {
            return true
        } else {
            let currentFirePhoto = oFirePhotos[index]
            let photoId = currentFirePhoto.id.uuidString
            let selectSavedPhotos = realmPhotos?.filter { $0.id == photoId }
            return (selectSavedPhotos?.count ?? 0) > 0
        }
    }

    func updateSaveCount(doc: OFirePhoto, up: Bool) {
        var newTotal = doc.totalSaveCount
        var newWeekly = doc.weeklySaveCount
        let currentStartDay = Date().dateAt(.startOfWeek).toString()
        if doc.weekStartDay != currentStartDay {
            newWeekly = 0
        }
        if up {
            newTotal += 1
            newWeekly += 1
        } else {
            if newTotal > 0 { newTotal -= 1 }
            if newWeekly > 0 { newWeekly -= 1 }
        }
        struct SaveCountUpdate: Codable {
            let total_save_count: Int
            let weekly_save_count: Int
            let week_start_day: String
            let updated_at: String
        }
        let update = SaveCountUpdate(
            total_save_count: newTotal,
            weekly_save_count: newWeekly,
            week_start_day: currentStartDay,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        Task {
            do {
                try await supabase.client.from("photos")
                    .update(update)
                    .eq("id", value: doc.id.uuidString)
                    .execute()
                print("savecount update success")
            } catch {
                print("savecount update error: \(error)")
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
            id = oFirePhotos[index].id.uuidString
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
                    Task {
                        do {
                            let photos: [OFirePhoto] = try await self.supabase.client
                                .from("photos")
                                .select()
                                .eq("id", value: id!)
                                .limit(1)
                                .execute()
                                .value
                            if let photo = photos.first {
                                self.updateSaveCount(doc: photo, up: false)
                            }
                        } catch {
                            print("fetch photo error: \(error)")
                        }
                    }
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
                photo = RealmPhoto.create(id: selectData.id.uuidString,
                                            text: selectData.title,
                                            image: image,
                                            imageHeight: selectData.imageHeight,
                                            imageWidth: selectData.imageWidth,
                                            getDay: Date().toString(),
                                            isPublic: true,
                                            ownerId: selectData.ownerId?.uuidString ?? "")
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
            self.showRewardedAd()
            
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
    
    
    func goPotoDetail(rPhoto: RealmPhoto?, fPhoto: OFirePhoto?, index: Int) {
        let sb = UIStoryboard(name: "PhotoDetail",bundle: nil)
        let vc = sb.instantiateInitialViewController() as! PhotoDetailViewController
        vc.rPhoto = rPhoto
        vc.fPhoto = fPhoto
        if checkSaved(index: index) {
            vc.savedFlag = true
        } else {
            vc.savedFlag = false
        }
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
        print("call didSelectItemAt")
        print("indexpath : ", indexPath)
        print("=========")
        if tabPageIndex == 0 {
            goPotoDetail(rPhoto: realmPhotos![indexPath.row], fPhoto: nil, index: indexPath.row)
        } else {
            goPotoDetail(rPhoto: nil, fPhoto: oFirePhotos[indexPath.row], index: indexPath.row)
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


extension ChildContentViewController {
    private var rewardedAd: GADRewardedAd? {
        get { objc_getAssociatedObject(self, &rewardedAdKey) as? GADRewardedAd }
        set { objc_setAssociatedObject(self, &rewardedAdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setUpAd() {
        loadRewardedAd()
    }

    func loadRewardedAd() {
        GADRewardedAd.load(withAdUnitID: addId, request: GADRequest()) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
        }
    }

    func showRewardedAd() {
        guard let rewardedAd = rewardedAd else {
            print("Rewarded ad not ready")
            return
        }
        rewardedAd.present(fromRootViewController: self) { [weak self] in
            let reward = rewardedAd.adReward
            print("Reward received: \(reward.type), amount \(reward.amount)")
            GroupeDefaults.shared.chargeSaveLife(amount: Int(truncating: reward.amount))
        }
        loadRewardedAd()
    }
}

private var rewardedAdKey: UInt8 = 0
