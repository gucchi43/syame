//
//  PhotoKeyboardExTests.swift
//  PhotoKeyboardExTests
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import XCTest
import UIKit
@testable import PhotoKeyboardEx

class PhotoKeyboardExTests: XCTestCase {

    // MARK: - 一覧のグリッド

    /// 高さを可変にすると同じ行の2つのセルで高さが揃わず隙間ができるため、
    /// 画面幅から一定の大きさを算出して全セルで共有する
    func testGridMetricsFitsTwoColumnsWithinContainer() {
        let containerWidth: CGFloat = 393
        let metrics = ChildContentViewController.gridMetrics(containerWidth: containerWidth)

        // 左右の余白8 + 列間8 + 2列ぶんの幅が画面幅に収まること
        let used = metrics.itemWidth * 2 + 8 * 3
        XCTAssertLessThanOrEqual(used, containerWidth)
        XCTAssertGreaterThan(metrics.itemWidth, 0)
    }

    /// 行の高さは正方形の画像 + 情報エリアで決まること
    func testGridRowHeightIsImagePlusInfoArea() {
        let metrics = ChildContentViewController.gridMetrics(containerWidth: 393)
        XCTAssertEqual(metrics.rowHeight, metrics.itemWidth + 68, accuracy: 0.001)
    }

    /// 幅が極端に狭くても破綻しないこと
    func testGridMetricsHandlesTinyContainer() {
        let metrics = ChildContentViewController.gridMetrics(containerWidth: 10)
        XCTAssertGreaterThan(metrics.itemWidth, 0)
        XCTAssertGreaterThan(metrics.rowHeight, 0)
    }

    // MARK: - バージョン比較

    /// メジャー番号を無視すると、端末の方が新しいのに更新を促してしまう
    func testVersionComparison() {
        XCTAssertTrue(AppDelegate.isVersion("1.0.0", olderThan: "1.0.1"))
        XCTAssertTrue(AppDelegate.isVersion("1.9.0", olderThan: "2.0.0"))
        XCTAssertFalse(AppDelegate.isVersion("2.0.0", olderThan: "1.9.0"))
        XCTAssertFalse(AppDelegate.isVersion("1.2.3", olderThan: "1.2.3"))
        XCTAssertTrue(AppDelegate.isVersion("1.2", olderThan: "1.2.1"))
    }
}
