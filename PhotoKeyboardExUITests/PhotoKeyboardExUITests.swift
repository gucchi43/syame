//
//  PhotoKeyboardExUITests.swift
//  PhotoKeyboardExUITests
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import XCTest

class PhotoKeyboardExUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        // 起動に失敗した時点で後続の検証は意味がないので即座に止める
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// Top を閉じた直後に、ボードへ「次にやること」が出ること。
    ///
    /// 案内行の更新を viewDidAppear だけに任せると、Top を閉じても呼ばれず
    /// 次の起動まで案内が出ないままになる。実際にその不具合が出たので固定する。
    func testHintAppearsRightAfterWelcome() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))

        let start = app.buttons["はじめる"]
        guard start.waitForExistence(timeout: 10) else {
            // 初回状態でなければこの検証は成立しない
            return
        }
        start.tap()

        let hint = app.staticTexts["好きな画像を1枚入れてみる"]
        XCTAssertTrue(hint.waitForExistence(timeout: 10),
                      "Top を閉じた直後にボードへ案内が出ていない")
    }

    /// 起動直後にクラッシュしないこと。
    /// AppDelegate は起動時にRealmの初期化・バージョン確認・広告SDKの初期化を行っており、
    /// ここが落ちるとアプリが一切使えない。ユニットテストではAppDelegateを通らないため
    /// 実際に起動して前面まで到達することを確認する。
    func testAppLaunchesAndStaysInForeground() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30),
                      "アプリが前面まで起動しなかった")
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10),
                      "起動したが画面が1つも表示されていない")
    }

    /// 起動後、いずれかの画面が実際に描画されていること。
    /// 初回起動ではオンボーディングが、2回目以降はタブ画面が出る。
    /// どちらも出ない = ルートのビューコントローラの生成に失敗している
    func testInitialScreenShowsInteractiveContent() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))

        let anyContent = app.descendants(matching: .any)
            .matching(NSPredicate(format: "elementType IN {%@, %@, %@}",
                                  NSNumber(value: XCUIElement.ElementType.button.rawValue),
                                  NSNumber(value: XCUIElement.ElementType.staticText.rawValue),
                                  NSNumber(value: XCUIElement.ElementType.image.rawValue)))
        XCTAssertTrue(anyContent.firstMatch.waitForExistence(timeout: 15),
                      "起動後に何も表示されていない。ルート画面の生成に失敗している可能性がある")
    }
}
