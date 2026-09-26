//
//  RealmManager.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/05.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

public protocol RealmManagerDelegate: AnyObject {
    func realmObjectDidChange()
}

public class RealmManager {
    public static let shared = RealmManager()

    /// シングルトンがViewControllerを保持し続けないようweakにする
    public weak var delegate: RealmManagerDelegate?

    private static let appGroupIdentifier = "group.bocchi.PhotoKeyboardEx"
    /// ロケールに依存しない統合後のRealmファイル名
    private static let realmFileName = "db.realm.shared"
    /// 旧バージョンがロケールごとに分けて作成していたファイル
    private static let legacyJPFileName = "db.realm.jp"
    private static let legacyWorldFileName = "db.realm.world"
    private static let legacyOriginalFileName = "db.realm"
    private static let schemaVersion: UInt64 = 2
    /// マイボードとキーボードの並び順
    static let orderKey = "pastedAt"

    private let configuration: Realm.Configuration
    /// 変更通知の購読はメインスレッドのRealmに紐づくため、その参照を保持しておく
    private var observedRealm: Realm?
    private var token: NotificationToken?

    /// スレッド拘束を避けるため、常に呼び出しスレッドのRealmから取得する
    public var realmData: Results<RealmPhoto> {
        return realm().objects(RealmPhoto.self).sorted(byKeyPath: RealmManager.orderKey)
    }

    /// 版 1 から上げるときに既存の写真へ入れる日時。
    /// 今見えている順番を変えないよう、1 秒ずつ増やして最後を基準の時刻にする
    static func migrationDates(count: Int, endingAt end: Date) -> [Date] {
        return (0..<count).map { end.addingTimeInterval(TimeInterval($0 - (count - 1))) }
    }

    private init() {
        let container = RealmManager.containerURL()
        RealmManager.applyFileProtection(to: container)
        let fileURL = container.appendingPathComponent(RealmManager.realmFileName)

        // 復元は Realm を開く前に済ませる。開いたあとに差し替えても、
        // 既に握られたファイルハンドルは古い本体を指したままになる。
        backup = RealmManager.makeBackup(sharedContainer: container)
        if backup.needsRestore {
            try? backup.restore(to: fileURL)
        }
        backup.markAlive()

        RealmManager.consolidateLegacyFilesIfNeeded(container: container, target: fileURL)
        configuration = RealmManager.makeConfiguration(fileURL: fileURL)
        startObserving()
    }

    // MARK: - 消失対策

    private let backup: RealmBackup
    /// 直前に複製を取ったときの件数。変化が無ければ作り直さない
    private var lastSnapshotCount: Int?

    /// 複製の置き場所はアプリ本体のコンテナ。
    /// 共有コンテナに置くと、守りたい相手(コンテナごとの消失)と一緒に消えて意味がない。
    private static func makeBackup(sharedContainer: URL) -> RealmBackup {
        let appContainer = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return RealmBackup(appContainer: appContainer, sharedContainer: sharedContainer)
    }

    /// 複製を取り直す。アプリが背面に回るときに呼ぶ。
    ///
    /// 件数が変わっていなければ何もしない。writeCopy はファイル全体を書き出すので、
    /// 毎回走らせると画像の枚数に比例して背面遷移が重くなる。
    public func snapshotIfNeeded() {
        let count = realmData.count
        guard count != lastSnapshotCount else { return }
        guard let realm = diskRealm() else { return }
        do {
            try backup.write(from: realm)
            lastSnapshotCount = count
        } catch {
            // 複製が作れなくても本体は無事なので、起動や保存は止めない
            print("realm snapshot error: \(error)")
        }
    }

    deinit {
        token?.invalidate()
    }

    // MARK: - Realm の生成

    /// 書き込み用。メモリ上のRealmに書いても消えるだけなので、開けない場合は nil を返して
    /// 呼び出し側に失敗として扱わせる。
    private func diskRealm() -> Realm? {
        return try? Realm(configuration: configuration)
    }

    /// 読み取り用。ディスク上のRealmを開けない場合でもアプリ・キーボードが起動不能にならないよう
    /// メモリ上のRealmへ退避する。
    private func realm() -> Realm {
        return diskRealm() ?? RealmManager.makeFallbackRealm()
    }

    private static func makeFallbackRealm() -> Realm {
        var fallback = Realm.Configuration()
        fallback.inMemoryIdentifier = "PhotoKeyboardFrameworkFallback"
        fallback.objectTypes = [RealmPhoto.self]
        // メモリ上のRealmはファイルI/Oを伴わないため生成に失敗する現実的な経路はない
        return try! Realm(configuration: fallback)
    }

    static func makeConfiguration(fileURL: URL) -> Realm.Configuration {
        var configuration = Realm.Configuration()
        configuration.fileURL = fileURL
        configuration.schemaVersion = schemaVersion
        configuration.migrationBlock = { migration, oldSchemaVersion in
            // deleteRealmIfMigrationNeeded はユーザーの保存画像を消してしまうため使わない。
            if oldSchemaVersion < 2 {
                var objects: [MigrationObject] = []
                migration.enumerateObjects(ofType: RealmPhoto.className()) { _, new in
                    if let new = new { objects.append(new) }
                }
                let dates = RealmManager.migrationDates(count: objects.count, endingAt: Date())
                for (object, date) in zip(objects, dates) {
                    object["pastedAt"] = date
                }
            }
        }
        configuration.objectTypes = [RealmPhoto.self]
        // 削除しても Realm のファイルは縮まない。肥大すると端末バックアップの容量を
        // 圧迫し、利用者に「このアプリのバックアップ」を切られる。
        // 10MB を超え、かつ半分以上が使われていない場合だけ起動時に詰める。
        configuration.shouldCompactOnLaunch = { totalBytes, usedBytes in
            let tenMB = 10 * 1024 * 1024
            return totalBytes > tenMB && Double(usedBytes) / Double(totalBytes) < 0.5
        }
        return configuration
    }

    private static func containerURL() -> URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return url
        }
        // App Group が使えない環境でも起動は継続させる(拡張とのデータ共有はできない)
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    /// 端末ロック中でもキーボード拡張からRealmを開けるようにする
    private static func applyFileProtection(to directory: URL) {
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: directory.path
        )
    }

    // MARK: - 旧ロケール別ファイルの統合

    /// 統合が済んだ目印。Realm 本体と同じ共有コンテナに置くことで、
    /// コンテナごと作り直されたときは目印も一緒に消え、次回また統合が走る(整合が取れる)。
    /// UserDefaults に置くと、コンテナは生きたまま目印だけ残る/消えるという食い違いが起きうる。
    private static let legacyConsolidationMarkerFileName = ".legacy-consolidated"

    private static func legacyConsolidationMarkerURL(container: URL) -> URL {
        return container.appendingPathComponent(legacyConsolidationMarkerFileName)
    }

    /// 旧バージョンは端末のロケールで db.realm.jp / db.realm.world を切り替えていたため、
    /// 言語設定を変えると保存済みの画像が消えたように見えていた。1つのファイルへ統合する。
    ///
    /// 「済み」は出力先(target)の有無ではなく目印ファイルで判定する。
    /// 出力先の有無で判定すると、初回の統合が(空き容量不足などで)失敗して
    /// 空の出力先だけができた場合に、次回以降は「統計済み」とみなされて
    /// 永久にやり直されなくなる。目印は全ファイルの取り込みが成功したときだけ書く。
    static func consolidateLegacyFilesIfNeeded(container: URL, target: URL) {
        let fileManager = FileManager.default
        let markerURL = legacyConsolidationMarkerURL(container: container)
        guard !fileManager.fileExists(atPath: markerURL.path) else { return }

        let legacyURLs = orderedLegacyURLs(container: container)
            .filter { fileManager.fileExists(atPath: $0.path) }
        guard !legacyURLs.isEmpty else { return }

        // target は importPhotos の中で(無ければ新規に、あれば開いたまま)使う。
        // 1つずつ独立した書き込みトランザクションで追加するため、
        // 事前にファイル全体を複製する(旧: writeCopy)必要がなく、
        // 空き容量は旧ファイル1つぶんの一時複製で済む。
        var allSucceeded = true
        for url in legacyURLs {
            if !importPhotos(from: url, into: target) {
                allSucceeded = false
            }
        }

        // 1つでも取り込みに失敗したら目印を書かず、次回の起動で全部やり直す。
        // id で重複を弾くため、成功済みの分をもう一度取り込んでも安全。
        guard allSucceeded else { return }
        fileManager.createFile(atPath: markerURL.path, contents: Data())
    }

    /// 旧ファイルの原本には触れず、書き込み可能な一時複製を移行してからクロージャに渡す。
    ///
    /// readOnly で開くと realm-core は移行(migrationBlock)を実行できず、
    /// pastedAt を足した今回のスキーマ差分で例外になり、呼び出し側の catch で
    /// 握りつぶされて「取り込めなかった」ことになるため、複製側だけ移行する。
    ///
    /// 複製の後片付けは autoreleasepool を抜けて Realm のインスタンスを
    /// 解放してから行う。生きたまま `.realm` だけを消すと `.lock` / `.note` /
    /// `.management` が古い本体を指したまま残り不整合になるため、
    /// `Realm.deleteFiles` でまとめて消す。
    /// `.lock` は deleteFiles の対象外(中身を持たず開くたびに作り直されるので、
    /// 長く使う本体なら残してよいファイル)だが、この複製は使い捨てで二度と
    /// 開かないため、名前が一意な `.legacy-migrating-` ファイルを溜めないよう
    /// あわせて消す。
    private static func withMigratedLegacyCopy<T>(of source: URL, _ body: (Realm) throws -> T) -> T? {
        let fileManager = FileManager.default
        let copyURL = source.deletingLastPathComponent()
            .appendingPathComponent(".legacy-migrating-\(UUID().uuidString).realm")
        do {
            try fileManager.copyItem(at: source, to: copyURL)
        } catch {
            // 途中まで複製された断片が残ることがあるので掃除しておく
            try? fileManager.removeItem(at: copyURL)
            return nil
        }

        let copyConfiguration = makeConfiguration(fileURL: copyURL)
        defer {
            try? Realm.deleteFiles(for: copyConfiguration)
            try? fileManager.removeItem(at: copyURL)
            try? fileManager.removeItem(at: copyURL.appendingPathExtension("lock"))
        }
        do {
            return try autoreleasepool {
                let realm = try Realm(configuration: copyConfiguration)
                return try body(realm)
            }
        } catch {
            return nil
        }
    }

    /// 現在のロケールに対応するファイルを優先する(順序自体は id で重複を弾くため結果に影響しない)
    private static func orderedLegacyURLs(container: URL) -> [URL] {
        let names: [String]
        if Lang.rootKey() == Lang.japaneseRootKey {
            names = [legacyJPFileName, legacyWorldFileName, legacyOriginalFileName]
        } else {
            names = [legacyWorldFileName, legacyJPFileName, legacyOriginalFileName]
        }
        return names.map { container.appendingPathComponent($0) }
    }

    /// 旧ファイルから未取り込みの写真だけを取り込む。id で判定するため、
    /// 前回どこまで成功したかに関わらず、何度実行しても安全(冪等)。
    /// 戻り値は取り込みが成功したか(取り込む写真が無かった場合も成功扱い)。
    @discardableResult
    private static func importPhotos(from source: URL, into target: URL) -> Bool {
        let result: Bool? = withMigratedLegacyCopy(of: source) { sourceRealm -> Bool in
            guard let targetRealm = try? Realm(configuration: makeConfiguration(fileURL: target)) else {
                return false
            }
            let existingIds = Set(targetRealm.objects(RealmPhoto.self).map { $0.id })
            let missing = sourceRealm.objects(RealmPhoto.self).filter { !existingIds.contains($0.id) }
            guard !missing.isEmpty else { return true }
            do {
                try targetRealm.write {
                    for photo in missing {
                        targetRealm.create(RealmPhoto.self, value: photo, update: .modified)
                    }
                }
                return true
            } catch {
                return false
            }
        }
        return result ?? false
    }

    // MARK: - 変更通知

    private func startObserving() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let realm = self.realm()
            self.observedRealm = realm
            // Realm 全体ではなく写真の一覧を監視し、件数が変わったときだけ通知する。
            // 画像のコピーで useNum を更新するたびに reloadData が走ると、選択直後に
            // セルが作り直されて再生中のアニメーションが別の写真のセルへ引き継がれてしまう。
            self.token = realm.objects(RealmPhoto.self).observe { [weak self] changes in
                switch changes {
                case .update(_, let deletions, let insertions, _):
                    guard !deletions.isEmpty || !insertions.isEmpty else { return }
                    self?.delegate?.realmObjectDidChange()
                case .initial, .error:
                    break
                }
            }
        }
    }

    // MARK: - CRUD

    // データを保存するための処理
    /// 保存できる枚数の上限。見本画像も数に入れる。
    ///
    /// 上限は制限ではなく道具の性格として置いている(DESIGN.md)。
    /// 厳選して持ち歩くという建て付けなので、数を増やす導線は今は用意していない。
    public static let photoLimit = 8

    /// 無料枠が数える枚数を求める。
    ///
    /// 見本画像も枠を消費する。例外を設けると「8枚のはずが9枚入る」ことになり、
    /// 上限の説明が破綻する。見本が要らない利用者は消せば枠が1つ空く。
    static func countTowardQuota(_ photos: [RealmPhoto]) -> Int {
        return photos.count
    }

    /// 利用者自身が保存した枚数。オンボーディングの進捗判定に使う。
    ///
    /// 見本は起動時に自動で入るため、無料枠の判定(`countTowardQuota`)とは別物。
    /// 混ぜると「1枚も入れていない人」を表現できなくなる。
    public var userOwnedPhotoCount: Int {
        return realmData.filter { $0.isUserOwned }.count
    }

    /// 無料枠が数えている枚数
    public var savedPhotoCount: Int {
        return RealmManager.countTowardQuota(Array(realmData))
    }

    /// あと1枚保存できるか。見本画像も枠を消費する。
    /// なお見本の投入(seedTutorialPhotoIfNeeded)はこの判定を通さない
    public var canSaveMorePhotos: Bool {
        return savedPhotoCount < RealmManager.photoLimit
    }

    public func save(data: RealmPhoto, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        guard let realm = diskRealm() else {
            failure("failure save...")
            return
        }
        do {
            try realm.write {
                realm.add(data, update: .modified)
            }
            success()
        } catch {
            failure("failure save...")
        }
    }

    // データを更新するための処理
    public func update(data: RealmPhoto, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        guard let realm = diskRealm() else {
            failure("failure update...")
            return
        }
        do {
            try realm.write {
                realm.add(data, update: .modified)
            }
            success()
        } catch {
            failure("failure update...")
        }
    }

    /// 使用回数だけを更新する。
    /// 未管理のコピーを作って上書きすると `image` の setter が走ってJPEGを再エンコードするため、
    /// 使うたびに画質が劣化し、キーボード拡張ではデコード/エンコードでメモリも消費する。
    public func incrementUseNum(id: String) {
        guard let realm = diskRealm(),
              let photo = realm.object(ofType: RealmPhoto.self, forPrimaryKey: id) else { return }
        try? realm.write {
            photo.useNum += 1
        }
    }

    // データを削除するための処理
    public func delete(docId: String, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        guard let realm = diskRealm() else {
            failure("failure delete...")
            return
        }
        do {
            guard let currentData = realm.object(ofType: RealmPhoto.self, forPrimaryKey: docId) else {
                success()
                return
            }
            try realm.write {
                realm.delete(currentData)
            }
            success()
        } catch {
            failure("failure delete...")
        }
    }
}

#if DEBUG
/// テスト専用。`pastedAt` を持たない旧スキーマの RealmPhoto 相当。
/// `_realmObjectName` で永続化上の型名を "RealmPhoto" に固定することで、
/// 本番の `RealmPhoto` 用スキーマとして移行(migrationBlock)を実際に走らせられる。
final class LegacyRealmPhotoFixture: Object {
    @objc dynamic var id = ""
    @objc dynamic var text = ""
    @objc dynamic var getDay = ""
    @objc dynamic var useNum = 0
    @objc dynamic var isPublic = false
    @objc dynamic var imageHeight = 0
    @objc dynamic var imageWidth = 0
    @objc dynamic var ownerId = ""

    override class func _realmObjectName() -> String { return "RealmPhoto" }
    override class func primaryKey() -> String? { return "id" }
}

extension RealmManager {
    /// `pastedAt` の無い旧スキーマのファイルを、指定した id の順番で書き込む。
    /// 「本番の移行を通しても写真が消えず、順番どおりに pastedAt が入る」ことを
    /// 確かめる移行テスト専用のヘルパー。
    static func writeLegacyFixture(ids: [String], schemaVersion: UInt64, to url: URL) throws {
        var configuration = Realm.Configuration()
        configuration.fileURL = url
        configuration.schemaVersion = schemaVersion
        configuration.objectTypes = [LegacyRealmPhotoFixture.self]
        // Realm はパスごとにインスタンスをキャッシュしており、スコープを抜けても
        // 自動解放プールが片付くまで生き続けることがある。生きたままだと、この直後に
        // 同じパスを別スキーマで開いたとき、そのキャッシュされたスキーマ情報が
        // 使い回されてしまう(新しい型が「管理されていない」ことになる)。
        // autoreleasepool で確実にここで解放してから返す。
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            try realm.write {
                for id in ids {
                    let fixture = LegacyRealmPhotoFixture()
                    fixture.id = id
                    realm.add(fixture)
                }
            }
        }
    }
}
#endif
