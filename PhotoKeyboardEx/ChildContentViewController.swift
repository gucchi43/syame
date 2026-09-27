//
//  ChildContentViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import RealmSwift
import Toast

/// マイボード(端末に保存済みの画像)。縦に続く方眼ノートに、貼った順で写真を貼っていく。
/// セクション 0 が写真、セクション 1 が「次はここ」(空状態も兼ねる)。データソースは Realm のみ。
class ChildContentViewController: UIViewController, RealmManagerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    /// 「次にやること」の常設案内。モーダルを閉じても手がかりが残るようにする
    private let onboardingHint = OnboardingHintView()
    private var onboardingStep: OnboardingStep = .done
    var realmPhotos: Results<RealmPhoto>?
    private let refreshControl = UIRefreshControl()
    private let journalLayout = JournalLayout()

    /// 直前に並べていた写真の id。増えた写真を見つけ、並びが同じ通知を見分けるために持つ
    private var knownPhotoIds: Set<String> = []

    private func currentPhotoIds() -> [String] {
        (realmPhotos.map { Array($0) } ?? []).map { $0.id }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        realmPhotos = RealmManager.shared.realmData
        RealmManager.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSaveState(notification:)), name: .updateSaveState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAfterPost(notification:)), name: .allReload, object: nil)
        commonInit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadBoard()
        knownPhotoIds = Set(currentPhotoIds())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 案内行が出ている間は、その高さぶんノートを下げて見出しと重ねない
        let inset = onboardingHint.isHidden ? 0 : onboardingHint.frame.maxY - view.safeAreaInsets.top + Spacing.s
        let previousInset = collectionView.contentInset.top
        if previousInset != inset {
            // 先頭で止まっているときだけ、先頭に留まるよう位置を合わせる。
            // スクロール中に inset が変わっても、利用者の位置は動かさない
            let wasAtTop = abs(collectionView.contentOffset.y + previousInset) < 1
            collectionView.contentInset.top = inset
            collectionView.verticalScrollIndicatorInsets.top = inset
            if wasAtTop {
                collectionView.contentOffset.y = -inset
            }
        }
    }

    /// いまの手順を受け取り、案内行の表示を更新する
    func applyOnboarding(step: OnboardingStep) {
        onboardingStep = step
        guard isViewLoaded else { return }
        onboardingHint.apply(step: step)
        // 案内行の出入りは isHidden を切り替えるだけで親のレイアウトが起きない。
        // 自分でレイアウトを起こして viewDidLayoutSubviews の inset を引き直す
        view.setNeedsLayout()
    }

    /// 案内行を一覧の上に敷く
    private func setupOnboardingHint() {
        onboardingHint.translatesAutoresizingMaskIntoConstraints = false
        onboardingHint.addTarget(self, action: #selector(tapOnboardingHint), for: .touchUpInside)
        view.addSubview(onboardingHint)

        NSLayoutConstraint.activate([
            onboardingHint.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                constant: Spacing.s),
            onboardingHint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.s),
            onboardingHint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s)
        ])
        onboardingHint.apply(step: onboardingStep)
    }

    /// 案内行を押したのと同じ経路を通す。押し先の検証に使う
    func simulateOnboardingHintTapForTesting() {
        tapOnboardingHint()
    }

    /// 案内行から、その手順の画面へ送る
    @objc private func tapOnboardingHint() {
        switch onboardingStep {
        case .savePhoto:
            // 保存は親のFABが持っている。同じ導線に乗せる
            NotificationCenter.default.post(name: .requestAddPhoto, object: nil)
        case .enableKeyboard, .allowFullAccess:
            // どちらも案内先は同じ「キーボードの設定」の画面
            guard let nvc = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController() else { return }
            present(nvc, animated: true)
        case .howToSend:
            present(UINavigationController(rootViewController: HowToSendViewController()), animated: true)
        case .welcome, .done:
            break
        }
    }

    func commonInit() {
        setupOnboardingHint()
        collectionView.dataSource = self
        collectionView.delegate = self
        journalLayout.itemsProvider = { [weak self] in self?.journalInputs() ?? [] }
        collectionView.collectionViewLayout = journalLayout
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.alwaysBounceVertical = true
        collectionView.register(PastedPhotoCell.self, forCellWithReuseIdentifier: PastedPhotoCell.reuseIdentifier)
        collectionView.register(NextSpotCell.self, forCellWithReuseIdentifier: NextSpotCell.reuseIdentifier)
        collectionView.register(JournalCaptionView.self,
                                forSupplementaryViewOfKind: JournalLayout.captionKind,
                                withReuseIdentifier: JournalCaptionView.reuseIdentifier)
        collectionView.register(JournalHeaderView.self,
                                forSupplementaryViewOfKind: JournalLayout.headerKind,
                                withReuseIdentifier: JournalHeaderView.reuseIdentifier)
        // 方眼は背景ビューではなく模様色で敷く。背景ビューはスクロールしても動かず、
        // 写真だけが方眼の上を滑ってしまうため
        collectionView.backgroundView = nil
        collectionView.backgroundColor = PaperBackgroundView.gridPattern
        refreshControl.addTarget(self, action: #selector(self
            .refresh(sender:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    /// 同じ日の写真を束ねるための日付キー
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    /// 荷札と見出しに書く日付
    private static let ticketFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    /// レイアウトに渡す写真の列。並びは Realm の pastedAt 昇順のまま
    private func journalInputs() -> [JournalItemInput] {
        (realmPhotos.map { Array($0) } ?? []).map { photo in
            let ratio = photo.imageHeight > 0 ? CGFloat(photo.imageWidth) / CGFloat(photo.imageHeight) : 1
            return JournalItemInput(id: photo.id, aspectRatio: ratio,
                                    dayKey: Self.dayFormatter.string(from: photo.pastedAt))
        }
    }

    /// 写真の列が変わったので、貼り方を計算し直してから描き直す
    private func reloadBoard() {
        guard let collectionView = collectionView else { return }
        journalLayout.invalidateLayout()
        collectionView.reloadData()
    }

    @objc func reloadAfterPost(notification: Notification) -> Void {
        reloadBoard()
    }

    @objc func reloadSaveState(notification: Notification) -> Void {
        reloadBoard()
        knownPhotoIds = Set(currentPhotoIds())
    }

    func realmObjectDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let ids = self.currentPhotoIds()
            // 貼る動きの途中で Realm の通知で作り直さない。並びが変わっていなければ何もしない
            if Set(ids) == self.knownPhotoIds && ids.count == self.collectionView.numberOfItems(inSection: 0) {
                return
            }
            self.reloadBoard()
            self.knownPhotoIds = Set(ids)
        }
    }

    @objc func refresh(sender: UIRefreshControl) {
        journalLayout.invalidateLayout()
        collectionView.reloadData {
            sender.endRefreshing()
        }
    }

    /// 写真を長押ししたときのメニュー。コピーと削除。
    /// 写真そのものは捕まえず id だけを持つ。別の経路で消えた写真に触れると Realm が例外で落ちるため
    private func makeMenu(forPhotoId id: String) -> UIMenu {
        let copy = UIAction(title: LocalizeKey.menuCopy.localizedString(),
                            image: .symbol(Symbol.copy)) { [weak self] _ in
            self?.copyPhoto(id: id)
        }
        let delete = UIAction(title: LocalizeKey.menuDelete.localizedString(),
                              image: .symbol(Symbol.delete),
                              attributes: .destructive) { [weak self] _ in
            self?.confirmDelete(id: id)
        }
        return UIMenu(children: [copy, delete])
    }

    /// 長押しメニューの題名の列。メニューの中身の検証に使う
    func contextMenuActionsForTesting(at indexPath: IndexPath) -> [String] {
        guard indexPath.section == 0, let photo = savedPhoto(at: indexPath.item) else { return [] }
        return makeMenu(forPhotoId: photo.id).children.map(\.title)
    }

    /// VoiceOver では長押しできないので、同じ操作をカスタムアクションで出す。メニューと同じく id だけを持つ
    private func accessibilityActions(forPhotoId id: String) -> [UIAccessibilityCustomAction] {
        let copy = UIAccessibilityCustomAction(name: LocalizeKey.menuCopy.localizedString()) { [weak self] _ in
            self?.copyPhoto(id: id)
            return true
        }
        let delete = UIAccessibilityCustomAction(name: LocalizeKey.menuDelete.localizedString()) { [weak self] _ in
            self?.confirmDelete(id: id)
            return true
        }
        return [copy, delete]
    }

    /// キーボードを開かなくても貼り付けられるようにする。
    /// フルアクセスの許可を得る前に価値を体験してもらうための導線。
    /// 実行した時点の Realm から id で引き直す。見つからないか、すでに消えていれば何もしない
    func copyPhoto(id: String) {
        guard let photo = RealmManager.shared.realmData.filter("id == %@", id).first,
              !photo.isInvalidated,
              let image = photo.image else { return }
        image.copyToPasteboardWithWatermark()
        RealmManager.shared.incrementUseNum(id: id)
        let toast = AuroraView.makeToast(message: LocalizeKey.copiedToast.localizedString(),
                                         maxWidth: view.bounds.width - Spacing.l * 2)
        view.showToast(toast, duration: 1.5, position: .center)
    }

    private func confirmDelete(id: String) {
        let alert = UIAlertController(title: nil,
                                      message: LocalizeKey.menuDeleteConfirm.localizedString(),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.menuDelete.localizedString(), style: .destructive) { _ in
            RealmManager.shared.delete(docId: id, success: {
                NotificationCenter.default.post(name: .updateSaveState, object: nil, userInfo: ["id": id, "saveFlag": false])
            }, failure: { error in
                print(error)
            })
        })
        alert.addAction(UIAlertAction(title: LocalizeKey.baseCancel.localizedString(), style: .cancel))
        present(alert, animated: true)
    }

    private func savedPhoto(at index: Int) -> RealmPhoto? {
        guard let realmPhotos = realmPhotos, index >= 0, index < realmPhotos.count else { return nil }
        return realmPhotos[index]
    }

    /// 貼り方を読む。普段は cellForItemAt より先にレイアウトの prepare が走っている。
    /// 未計算なら nil を返し、ここから prepare を呼んで UIKit の知らない所で属性を差し替えることはしない
    private func placement(at index: Int) -> JournalPlacement? {
        return journalLayout.placements.indices.contains(index) ? journalLayout.placements[index] : nil
    }

    func showPhotoDetail(rPhoto: RealmPhoto) {
        let sb = UIStoryboard(name: "PhotoDetail",bundle: nil)
        guard let vc = sb.instantiateInitialViewController() as? PhotoDetailViewController else { return }
        vc.rPhoto = rPhoto
        present(vc, animated: true, completion: nil)
    }
}

extension ChildContentViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // 0: 写真、1: 次はここ
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? (realmPhotos?.count ?? 0) : 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NextSpotCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? NextSpotCell {
                let count = realmPhotos?.count ?? 0
                cell.configure(state: count >= RealmManager.photoLimit
                               ? .full
                               : .next(remaining: RealmManager.photoLimit - count))
            }
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PastedPhotoCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? PastedPhotoCell,
           let photo = savedPhoto(at: indexPath.item),
           let placement = placement(at: indexPath.item) {
            let ticketText = placement.prop == .ticket ? Self.ticketFormatter.string(from: photo.pastedAt) : nil
            cell.configure(image: photo.thumbnail(maxPixelSize: 900) ?? photo.image,
                           placement: placement,
                           ticketText: ticketText,
                           title: photo.text)
            cell.accessibilityCustomActions = accessibilityActions(forPhotoId: photo.id)
        } else {
            // 貼り方が未計算なら空のまま返す。次のレイアウトで描き直される
            cell.accessibilityCustomActions = nil
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case JournalLayout.headerKind:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: JournalHeaderView.reuseIdentifier,
                                                                       for: indexPath)
            // ノートの書き出しの日付。写真が無ければ今日
            let date = realmPhotos?.first?.pastedAt ?? Date()
            (view as? JournalHeaderView)?.configure(dateText: Self.ticketFormatter.string(from: date))
            return view
        default:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: JournalLayout.captionKind,
                                                                       withReuseIdentifier: JournalCaptionView.reuseIdentifier,
                                                                       for: indexPath)
            (view as? JournalCaptionView)?.configure(text: savedPhoto(at: indexPath.item)?.text ?? "")
            return view
        }
    }
}

extension ChildContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            // いっぱいのときは追加の導線に乗せない
            guard (realmPhotos?.count ?? 0) < RealmManager.photoLimit else { return }
            NotificationCenter.default.post(name: .requestAddPhoto, object: nil)
            return
        }
        guard let photo = savedPhoto(at: indexPath.item) else { return }
        showPhotoDetail(rPhoto: photo)
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
                        point: CGPoint) -> UIContextMenuConfiguration? {
        // 写真 1 枚への長押しだけにメニューを出す。「次はここ」には出さない
        guard indexPaths.count == 1, let indexPath = indexPaths.first, indexPath.section == 0,
              let id = savedPhoto(at: indexPath.item)?.id else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            self?.makeMenu(forPhotoId: id)
        }
    }
}
