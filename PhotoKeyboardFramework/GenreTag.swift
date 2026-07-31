//
//  GenreTag.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/13.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation

public enum GenreTagType: String, CaseIterable {
    case myBoard = "マイボード"
    case new =  "新着"
    case popular = "人気"
    case humor = "ユーモア"
    case cool = "クール"
    case cute =  "キュート"
    case serious = "シリアス"
    case other = "その他"

    public func getKey() -> String {
        switch self {
        case .myBoard:
            return "myBoard"
        case .new:
            return "new"
        case .popular:
            return "popular"
        case .humor:
            return "humor"
        case .cool:
            return "cool"
        case .cute:
            return "cute"
        case .serious:
            return "serious"
        case .other:
            return "other"
        }
    }
    
    public func getEmoji() -> String {
        switch self {
        case .myBoard:
            return "⌨️"
        case .new:
            return "🆕"
        case .popular:
            return "🕺"
        case .humor:
            return "🌈"
        case .cool:
            return "🐧"
        case .cute:
            return "💖"
        case .serious:
            return "⚡️"
        case .other:
            return "👻"
        }
    }
    
    public func getLocalizeString() -> String {
        switch self {
        case .myBoard:
            return LocalizeKey.subGenreMyBoard.localizedString()
        case .new:
            return LocalizeKey.subGenreNew.localizedString()
        case .popular:
            return LocalizeKey.subGenrePopular.localizedString()
        case .humor:
            return LocalizeKey.genreHumor.localizedString()
        case .cool:
            return LocalizeKey.genreCool.localizedString()
        case .cute:
            return LocalizeKey.genreCute.localizedString()
        case .serious:
            return LocalizeKey.genreSerious.localizedString()
        case .other:
            return LocalizeKey.genreOther.localizedString()
        }
    }
    
    public static func getTypeFromTitle(title: String) -> GenreTagType? {
        for type in self.allCases {
            if type.getLocalizeString() == title {
                return type
            }
        }
        return nil
    }
    
    public static func getAllGenreTags() -> [GenreTagType] {
        return GenreTagType.allCases
    }
    
    public static func getAddAllGenreTitles() -> [String] {
        var array = GenreTagType.allCases.map { $0.getLocalizeString() }
        // マイボード、新着、人気のタグを除く
        array.removeSubrange(0...2)
        return array
    }
}
