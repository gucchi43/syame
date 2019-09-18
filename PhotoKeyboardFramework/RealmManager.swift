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

public protocol RealmManagerDelegate {
    func realmObjectDidChange()
}

public class RealmManager {
    public static let shared = RealmManager()
    
    public var delegate: RealmManagerDelegate?

    public var realmData: Results<RealmPhoto>!
    private var realm: Realm!
    private var configuration: Realm.Configuration!
    private var token: NotificationToken?
    
    private init() {
        configuration = Realm.Configuration()
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bocchi.PhotoKeyboardEx")!
        configuration.fileURL = url.appendingPathComponent("db.realm")
        configuration.deleteRealmIfMigrationNeeded = true
        do {
            realm = try Realm(configuration: configuration)
            token = realm.observe{ notification, realm in
                print("notification :", notification)
                print("realm :", realm)
                print("token :", self.token)
                self.delegate?.realmObjectDidChange()
            }
        } catch let error as NSError{
            assertionFailure("realm error: \(error)")

            // dbリセット, migrationするコードらへん
            // 参考:  https://ja.stackoverflow.com/questions/24905/realmswift%E3%81%AE%E3%83%9E%E3%82%A4%E3%82%B0%E3%83%AC%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6
//            var configuration = self.configuration
//            configuration!.deleteRealmIfMigrationNeeded = true
//            realm = try? Realm(configuration: configuration!)
        }
        
        realmData = realm.objects(RealmPhoto.self)
        print("realm init done!!!")
        print("realmData : ", realmData)
        print("realm.configuration.fileURL : ", realm.configuration.fileURL)

    }
    
    
    // データを保存するための処理
    public func save(data: RealmPhoto, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        do {
            try realm.write {
                realm.add(data)
            }
            print("realm save 成功")
            success()
        } catch let error as NSError {
            assertionFailure("realm save error: \(error)")
            failure("failure save...")
        }
    }
    
    // データを更新するための処理
    public func update(data: RealmPhoto, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        
        print("call realm update:", data)
        
        do {
            let savedData = realmData.filter{$0.id == data.id}
            if var currentData = savedData.first {
                try realm.write {
                    realm.add(data, update: .all)
                    print("realm update 成功")
                }
            }
            success()
        } catch let error as NSError {
            assertionFailure("realm delete error: \(error)")
            failure("failure delete...")
        }
    }
    
    // データを削除するための処理
    public func delete(docId:  String, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
//        let realm = try! Realm()
//        let data = realm.objects(Human).last!
        
        do {
            let savedData = realmData.filter{$0.id == docId}
            if let currentData = savedData.first {
                try realm.write {
                    print("idがマッチしたphotoデータのarray: ", savedData)
                    print("削除するrealmdata: ", currentData)
                    
                    realm.delete(currentData)
                    print("realm delete 成功")
                }
            }            
            success()
        } catch let error as NSError {
            assertionFailure("realm delete error: \(error)")
            failure("failure delete...")
        }
    }
}
