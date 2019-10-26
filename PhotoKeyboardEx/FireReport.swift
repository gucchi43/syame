//
//  FireReport.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/10/26.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import PhotoKeyboardFramework

struct FireReport: Codable, Equatable {
    var userId: String
    var ownerId: String
    var contentId: String
    var reason: String
    var imageUrl: String?
}
