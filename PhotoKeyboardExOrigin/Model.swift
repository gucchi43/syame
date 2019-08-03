//
//  Model.swift
//  PhotoKeyboardExOrigin
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

struct Model {
    var no: Int
    var title: String
    var photo: UIImage
    var isSelected: Bool
    
    static func createModels() -> [Model] {
        return [
            Model(no: 0, title: "落とし穴・・・？", photo: UIImage(named: "otoshi")!,isSelected: false),
            Model(no: 1, title: "ただ深く", photo: UIImage(named: "tadahukaku")!,isSelected: false),
            Model(no: 2, title: "勝てる勝てないじゃなくここで俺はお前に立ち向かわなくちゃいけないんだ！", photo: UIImage(named: "katerukatenai")!,isSelected: false),
            Model(no: 3, title: "これパクってもいい？", photo: UIImage(named: "paku")!,isSelected: false),
            Model(no: 4, title: "やらなければ一生わからん‼︎", photo: UIImage(named: "yaranakereba")!,isSelected: false),
            Model(no: 5, title: "だけど不自由であることと不幸である事はイコールじゃない哀れに思われるいわれは無いよ！", photo: UIImage(named: "dakedo")!,isSelected: false),
            Model(no: 6, title: "きみはかんちがいをしているんだ。道をえらぶということはかならずしも歩きやすい安全な道をえらぶってことじゃないんだぞ。", photo: UIImage(named: "kimihakantigai")!,isSelected: false),
            Model(no: 7, title: "だが断る", photo: UIImage(named: "daga")!,isSelected: false),
            Model(no: 8, title: "スターの現れる前兆って気がしませんか？", photo: UIImage(named: "star")!,isSelected: false),
            Model(no: 9, title: "「僕」って言った。店長、いつも「俺」って言うのに、「僕」って言った。", photo: UIImage(named: "bokutte")!,isSelected: false),
            Model(no: 10, title: "左手はそえるだけ・・・", photo: UIImage(named: "hidarite")!,isSelected: false),
            Model(no: 11, title: "ゆるさーん", photo: UIImage(named: "yurusan")!,isSelected: false),
            Model(no: 12, title: "自然に生きたい・・・自由に・・・　何のしがらみもなく・・・", photo: UIImage(named: "shizen")!,isSelected: false),
            Model(no: 13, title: "もうペロペロ", photo: UIImage(named: "pero")!,isSelected: false),
            Model(no: 14, title: "おまえーっおまえ・・・人間がなーっバッタをなーっ", photo: UIImage(named: "omae")!,isSelected: false),
            Model(no: 15, title: "自然に生きたい・・・自由に・・・　何のしがらみもなく・・・", photo: UIImage(named: "shizen")!,isSelected: false)
        ]
        
    }
}
