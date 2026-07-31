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
    private static let schemaVersion: UInt64 = 1

    private let configuration: Realm.Configuration
    /// 変更通知の購読はメインスレッドのRealmに紐づくため、その参照を保持しておく
    private var observedRealm: Realm?
    private var token: NotificationToken?

    /// スレッド拘束を避けるため、常に呼び出しスレッドのRealmから取得する
    public var realmData: Results<RealmPhoto> {
        return realm().objects(RealmPhoto.self)
    }

    private init() {
        let container = RealmManager.containerURL()
        RealmManager.applyFileProtection(to: container)
        let fileURL = container.appendingPathComponent(RealmManager.realmFileName)
        RealmManager.consolidateLegacyFilesIfNeeded(container: container, target: fileURL)
        configuration = RealmManager.makeConfiguration(fileURL: fileURL)
        startObserving()
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

    private static func makeConfiguration(fileURL: URL, readOnly: Bool = false) -> Realm.Configuration {
        var configuration = Realm.Configuration()
        configuration.fileURL = fileURL
        configuration.readOnly = readOnly
        configuration.schemaVersion = schemaVersion
        configuration.migrationBlock = { _, _ in
            // スキーマを変更したらここに移行処理を追加する。
            // deleteRealmIfMigrationNeeded はユーザーの保存画像を消してしまうため使わない。
        }
        configuration.objectTypes = [RealmPhoto.self]
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

    /// 旧バージョンは端末のロケールで db.realm.jp / db.realm.world を切り替えていたため、
    /// 言語設定を変えると保存済みの画像が消えたように見えていた。初回起動時に1つのファイルへ統合する。
    private static func consolidateLegacyFilesIfNeeded(container: URL, target: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: target.path) else { return }

        let legacyURLs = orderedLegacyURLs(container: container)
            .filter { fileManager.fileExists(atPath: $0.path) }
        guard let primary = legacyURLs.first else { return }

        // 直接 target へ書くと途中で失敗したときに壊れたファイルが残り、次回以降は
        // 「statごと存在する」ため統合がスキップされて永久に復旧できなくなる。
        // 一時ファイルへ書いてから原子的に差し替える。
        let temporaryURL = target.appendingPathExtension("tmp")
        try? fileManager.removeItem(at: temporaryURL)
        do {
            // 旧ファイルはインプレース移行させたくないので読み取り専用で開く
            let primaryRealm = try Realm(configuration: makeConfiguration(fileURL: primary, readOnly: true))
            try primaryRealm.writeCopy(toFile: temporaryURL)
            try fileManager.moveItem(at: temporaryURL, to: target)
        } catch {
            // 統合できない場合は空のファイルとして開始する(旧ファイルは残すので復旧は可能)
            try? fileManager.removeItem(at: temporaryURL)
            return
        }

        for url in legacyURLs.dropFirst() {
            importPhotos(from: url, into: target)
        }
    }

    /// 現在のロケールに対応するファイルを優先して統合元にする
    private static func orderedLegacyURLs(container: URL) -> [URL] {
        let names: [String]
        if Lang.rootKey() == Lang.japaneseRootKey {
            names = [legacyJPFileName, legacyWorldFileName, legacyOriginalFileName]
        } else {
            names = [legacyWorldFileName, legacyJPFileName, legacyOriginalFileName]
        }
        return names.map { container.appendingPathComponent($0) }
    }

    private static func importPhotos(from source: URL, into target: URL) {
        do {
            let sourceRealm = try Realm(configuration: makeConfiguration(fileURL: source, readOnly: true))
            let targetRealm = try Realm(configuration: makeConfiguration(fileURL: target))
            let existingIds = Set(targetRealm.objects(RealmPhoto.self).map { $0.id })
            let missing = sourceRealm.objects(RealmPhoto.self).filter { !existingIds.contains($0.id) }
            guard !missing.isEmpty else { return }
            try targetRealm.write {
                for photo in missing {
                    targetRealm.create(RealmPhoto.self, value: photo, update: .modified)
                }
            }
        } catch {
            // 取り込めなかった旧ファイルはそのまま残す
        }
    }

    // MARK: - 変更通知

    private func startObserving() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let realm = self.realm()
            self.observedRealm = realm
            self.token = realm.observe { [weak self] _, _ in
                self?.delegate?.realmObjectDidChange()
            }
        }
    }

    // MARK: - CRUD

    // データを保存するための処理
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
