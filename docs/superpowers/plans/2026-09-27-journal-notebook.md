# ずっと続くノート 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** マイボードを、方眼ノートに写真を無造作に貼って縦へストックしていく見た目にする。

**Architecture:** 貼り方は写真の id から決める純粋関数 `JournalPlacer` が計算し、`UICollectionViewLayout` の派生 `JournalLayout` がそれを枠と回転に変える。写真は `PastedPhotoCell`、題名は補助ビュー `JournalCaptionView`、最後の「次はここ」は第 2 セクションの 1 セル `NextSpotCell`。色と書体はトークンで持ち、既存トークンは名前を残して値だけ紙とインクに替える。

**Tech Stack:** Swift 5 / UIKit（iOS 16+）/ RealmSwift / XCTest。プロジェクトへのファイル追加は `xcodeproj` gem（Ruby、1.28.1 導入済み）。

**Spec:** `docs/superpowers/specs/2026-09-27-journal-notebook-design.md`

## Global Constraints

- コードコメント・テストの説明・コミットメッセージは日本語。ファイルに絵文字を書かない
- 作業ブランチ `feature/journal-notebook`（master から作成済み）。`git checkout` / `git push` はしない（push と PR は最後のタスクで controller が行う）
- コミットは `git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit`。末尾に `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>` と `Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc` の 2 行
- キーボード拡張（`PhotoKeyboardExOrigin`）のコードは触らない。書体も拡張には入れない
- マイボード以外の画面（Top / HowToSend / Usage / Add / PhotoDetail / メニュー / 起動画面）の組み方は変えない。色トークンの値が変わるのは許容
- 上限は `RealmManager.photoLimit`（今は 8）。画面側で数を直書きしない
- 写真の色は加工しない
- 貼り方に `hashValue` や乱数を使わない（起動ごとに変わる）。FNV-1a 64 ビットを使う
- 文字の色は背景に対して 4.5:1 以上（ライト・ダーク両方）
- 新しい文言は `LocalizeKey` と ja / en の `Localizable.strings` の両方に足す（`testAllLocalizeKeysHaveTranslations` が漏れを拾う）
- テストコマンド（timeout 900000 ms）:
  - Framework: `xcodebuild test -project PhotoKeyboardEx.xcodeproj -scheme PhotoKeyboardEx -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PhotoKeyboardFrameworkTests 2>&1 | grep -E "error:|failed -|Executed [0-9]+ tests|TEST (SUCCEEDED|FAILED)" | tail -5`
  - アプリ: 同じコマンドで `-only-testing:PhotoKeyboardExTests`
  - 単一: `-only-testing:PhotoKeyboardExTests/PhotoKeyboardExTests/<テスト名>`（Framework も同形）
- 新しい Swift ファイルの登録（objectVersion 54、同期グループ無し）:

```ruby
# ruby -e で実行する。TARGET と GROUP と FILES を書き換えて使う
require 'xcodeproj'
project = Xcodeproj::Project.open('PhotoKeyboardEx.xcodeproj')
target = project.targets.find { |t| t.name == TARGET }            # "PhotoKeyboardEx" / "PhotoKeyboardFramework"
group = project.main_group.find_subpath(GROUP, true)              # 例 "PhotoKeyboardEx/Journal"
group.set_source_tree('<group>')
group.path = File.basename(GROUP) if group.path.nil? && GROUP.include?('/')
refs = FILES.map { |f| group.new_reference(f) }
target.add_file_references(refs)                                  # .swift は Sources へ
# 書体などの資源は target.resources_build_phase.add_file_reference(ref) で Resources へ
project.save
```

登録後は `grep -n "<ファイル名>" PhotoKeyboardEx.xcodeproj/project.pbxproj` で、PBXBuildFile / PBXFileReference / グループ / ビルドフェーズの 4 か所に出ることを確認する。

---

## ファイル構成

| 操作 | パス | 役割 |
|---|---|---|
| 変更 | `DESIGN.md` | 方針をジャーナルに改訂 |
| 変更 | `PhotoKeyboardFramework/DesignSystem.swift` | 既存色トークンの値を紙とインクに |
| 作成 | `PhotoKeyboardFramework/Journal.swift` | 追加の色、`UIFont.journal` / `UIFont.label` |
| 作成 | `PhotoKeyboardFramework/Motion.swift` | 押下・貼る動き、視差効果の設定、振動 |
| 変更 | `PhotoKeyboardFramework/Photo.swift` | `pastedAt` |
| 変更 | `PhotoKeyboardFramework/RealmManager.swift` | スキーマ版 2、移行、`realmData` の並び |
| 変更 | `PhotoKeyboardFramework/DefaultsKeys.swift` | `hasCelebratedNotebookFull` |
| 作成 | `PhotoKeyboardEx/Fonts/ZenKurenaido-Regular.ttf`、`SpecialElite-Regular.ttf`、`OFL-ZenKurenaido.txt`、`LICENSE-SpecialElite.txt` | 書体とライセンス |
| 変更 | `PhotoKeyboardEx/Info.plist` | `UIAppFonts` |
| 作成 | `PhotoKeyboardEx/Journal/JournalPlacer.swift` | FNV-1a と貼り方の計算（純粋関数） |
| 作成 | `PhotoKeyboardEx/Journal/JournalProps.swift` | 方眼の紙、テープ、クリップ、荷札、星の描画 |
| 作成 | `PhotoKeyboardEx/Journal/JournalLayout.swift` | レイアウト |
| 作成 | `PhotoKeyboardEx/Journal/PastedPhotoCell.swift` | 写真 1 枚 |
| 作成 | `PhotoKeyboardEx/Journal/JournalCaptionView.swift` | 題名 |
| 作成 | `PhotoKeyboardEx/Journal/NextSpotCell.swift` | 「次はここ」「あと n 枚」「このノートはいっぱい」 |
| 作成 | `PhotoKeyboardEx/Journal/JournalHeaderView.swift` | 日付と p.1 |
| 作成 | `PhotoKeyboardEx/Journal/StickerButton.swift` | 丸いシールの追加ボタン |
| 変更 | `PhotoKeyboardEx/ChildContentViewController.swift` | 組み替え |
| 変更 | `PhotoKeyboardEx/Onboarding/OnboardingHintView.swift` | 付箋 |
| 変更 | `PhotoKeyboardEx/MainTabViewController.swift` | シール、ロゴ |
| 変更 | `PhotoKeyboardEx/AddViewController.swift` | 保存の知らせをシートが閉じてから |
| 削除 | `PhotoKeyboardEx/PhotoCollectionViewCell.swift` | 旧セル |
| 変更 | 両テストファイル | 追加・書き換え・削除 |

---

### Task 1: 方針の改訂と色トークン

**Files:**
- Modify: `DESIGN.md`
- Modify: `PhotoKeyboardFramework/DesignSystem.swift:72-110`（色の値とコメント）
- Create: `PhotoKeyboardFramework/Journal.swift`（登録: `PhotoKeyboardFramework` ターゲット、グループ `PhotoKeyboardFramework`）
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Produces: `UIColor.paperGrid`、`UIColor.pencil`、`UIColor.tapeWhite`、`UIColor.tapeClear`、`UIColor.kraft`（すべて public、ライト・ダーク両値）。既存の `bgBase` / `bgSurface` / `textPrimary` / `textSecondary` / `accent` / `onAccent` / `accentSoft` の値が変わる

- [ ] **Step 1: 落ちるテストを書く**

`// MARK: - デザイントークン` の `testTextColorsMeetContrastRequirement` の直後に足す（`contrastRatio` は同ファイルの既存ヘルパー）。

```swift
    /// 紙の上のペンと鉛筆は、ライト・ダークとも本文として読めること。
    /// モックの鉛筆(#9A958B)は紙に対して 2.8:1 しかなく、濃くして 4.5:1 を超えさせた
    func testInkAndPencilAreReadableOnPaper() {
        for dark in [false, true] {
            let mode = dark ? "ダーク" : "ライト"
            XCTAssertGreaterThanOrEqual(contrastRatio(.textPrimary, .bgBase, dark: dark), 4.5, "\(mode): ペンが紙に沈む")
            XCTAssertGreaterThanOrEqual(contrastRatio(.pencil, .bgBase, dark: dark), 4.5, "\(mode): 鉛筆が読めない")
            XCTAssertGreaterThanOrEqual(contrastRatio(.textPrimary, .accentSoft, dark: dark), 4.5, "\(mode): 付箋の上の文字が読めない")
            XCTAssertGreaterThanOrEqual(contrastRatio(.onAccent, .accent, dark: dark), 4.5, "\(mode): テープの上の文字が読めない")
        }
    }

    /// 紙はライトで明るく、ダークで暗いこと。逆だと黒い紙のノートにならない
    func testPaperFlipsWithAppearance() {
        func white(_ color: UIColor, dark: Bool) -> CGFloat {
            var w: CGFloat = 0
            color.resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light)).getWhite(&w, alpha: nil)
            return w
        }
        XCTAssertGreaterThan(white(.bgBase, dark: false), 0.9)
        XCTAssertLessThan(white(.bgBase, dark: true), 0.15)
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: 単一テスト `testInkAndPencilAreReadableOnPaper`
Expected: コンパイルエラー（`UIColor.pencil` が無い）。

- [ ] **Step 3: 色を替える**

`DesignSystem.swift` の該当トークンを次の値に置き換え、各コメントを「紙」「ペン」などの役割に書き直す（旧方針の実測の説明は削る）。

```swift
    /// 紙。方眼ノートの地。ダークでは黒い紙
    public static let bgBase = adaptive(light: 0xF8F7F2, dark: 0x1B1A1E)
    /// ポラロイドの枠やメモの下地。紙より一段明るい(ダークでは一段明るい黒)
    public static let bgSurface = adaptive(light: 0xFFFEFB, dark: 0x242328)
    /// ペン
    public static let textPrimary = adaptive(light: 0x1E1C1A, dark: 0xEFEBE3)
    /// 鉛筆。補足と「次はここ」。紙に対して 4.5:1 を保つ濃さ
    public static let textSecondary = adaptive(light: 0x6E695F, dark: 0x9A958B)
    /// テープ。ライトは黒、ダークは白
    public static let accent = adaptive(light: 0x1C1B19, dark: 0xEDEAE2)
    /// テープの上の文字
    public static let onAccent = adaptive(light: 0xF8F7F2, dark: 0x1B1A1E)
    /// 付箋
    public static let accentSoft = adaptive(light: 0xF6E7A1, dark: 0x5A5230)
```

`separatorLine`、`keyboardBase`、`keyboardSurface`、`onAurora`、`onAuroraShadow`、`Aurora` は触らない（キーボードと範囲外の画面が使う）。

`Journal.swift` を作る。

```swift
//
//  Journal.swift
//  PhotoKeyboardFramework
//
//  ノートの紙・インク・テープの色と、手書きとタイプライターの書体。
//  方針は DESIGN.md と docs/superpowers/specs/2026-09-27-journal-notebook-design.md。
//

import UIKit

extension UIColor {
    fileprivate static func journalAdaptive(light: UInt32, lightAlpha: CGFloat = 1,
                                            dark: UInt32, darkAlpha: CGFloat = 1) -> UIColor {
        func make(_ hex: UInt32, _ alpha: CGFloat) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
        }
        return UIColor { $0.userInterfaceStyle == .dark ? make(dark, darkAlpha) : make(light, lightAlpha) }
    }

    /// 方眼の線
    public static let paperGrid = journalAdaptive(light: 0x788296, lightAlpha: 0.12, dark: 0xC8CDDC, darkAlpha: 0.12)
    /// 鉛筆。textSecondary と同じ色を、ノートの文脈で呼ぶための名前
    public static let pencil = UIColor.textSecondary
    /// 白いテープ(ライトでもダークでも白)
    public static let tapeWhite = journalAdaptive(light: 0xEDEAE2, dark: 0xEDEAE2)
    /// 透明なテープ
    public static let tapeClear = journalAdaptive(light: 0xFFFFFF, lightAlpha: 0.45, dark: 0xFFFFFF, darkAlpha: 0.22)
    /// 荷札・星のシール
    public static let kraft = journalAdaptive(light: 0xE9DFC6, dark: 0xCDBF9E)
}
```

`DESIGN.md` を改訂する。`## 決定した方向性` から `## 参照した実測データ` の直前までを次に置き換え、`## デザイン原則` の 5 項目、`### 角丸`、`### 影とブラー`、`## 移行ステップ` 以降も次の内容に合わせて書き換える（他の節は旧方針の記録として残し、節の冒頭に「2026-09-27 以前の記録」と一行添える）。

```markdown
## 決定した方向性

**日記帳の方眼ノートに、写真を無造作に貼ってストックしていく。**

2026-09-27 に決めた。経緯と詳細は `docs/superpowers/specs/2026-09-27-journal-notebook-design.md`。
その前の 2 つの方針（静かなミニマル、クレイ質感）は実機で「地味・安っぽい」と判断して退けた。
クレイ案は `feature/clay-game-ui` と `一時素材/design/` にストックしてある。

- 紙は方眼ノート。ダークは黒い紙に白いペンと白いテープ
- 写真は縦に続く 1 冊のノートに、貼った順に下へ。整った格子にしない
- 形・角度・テープは写真の id から決める。毎回同じ場所に同じ貼り方で出る
- 装飾は実在する文房具だけ（テープ・付箋・ポラロイド・クリップ・荷札・星のシール）
- 書体は手書き（Zen Kurenaido）とタイプライター（Special Elite）
- 写真の色は加工しない

## デザイン原則

1. **貼ってあるように見せる。** 押せることは膨らみではなく、テープ・傾き・影で伝える
2. **無造作は決定的に作る。** 乱数ではなく id から決め、1 枚足しても前の写真は動かさない
3. **文字は読める濃さにする。** 鉛筆も紙に対して 4.5:1 以上
4. **写真を主役にする。** 小物は写真の 1/5 程度にしか付けない
5. **文房具として存在しない装飾はしない**

## 移行ステップ

| 段階 | 内容 | 状態 |
|---|---|---|
| 1 | マイボードをノートにする（この計画） | |
| 2 | 残りの画面を紙とインクに合わせる | |
| 3 | キーボードをフィルムのコンタクトシートにする | |
```

- [ ] **Step 4: 通ることを確認**

Run: 単一 2 本 → Framework 全体 → アプリ全体
Expected: すべて PASS。既存の `testTextColorsMeetContrastRequirement`、`testAccentIsUsableAsUIComponentColor`、`testAccentSoftStaysAsSurface` が新しい値で落ちた場合は、**テストの意図**（文字が読める / アクセントが部品色として見える / 付箋が面として淡い）を保ったまま、新しい役割に合う基準へ直す。直したテストと理由を報告に書く。

- [ ] **Step 5: コミット** — 件名「方針をジャーナルに改め、色を紙とインクにする」

---

### Task 2: 書体を同梱する

**Files:**
- Create: `PhotoKeyboardEx/Fonts/`（書体 2 つとライセンス 2 つ。`PhotoKeyboardEx` ターゲットの Resources に登録）
- Modify: `PhotoKeyboardEx/Info.plist`（`UIAppFonts`）
- Modify: `PhotoKeyboardFramework/Journal.swift`（書体の関数）
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`（アプリのバンドルで書体が読めるかを見るため、アプリ側のテストに置く）

**Interfaces:**
- Produces: `UIFont.journal(_ style: UIFont.TextStyle) -> UIFont`（Zen Kurenaido）、`UIFont.label(_ style: UIFont.TextStyle) -> UIFont`（Special Elite）、`UIFont.journalFontName = "ZenKurenaido-Regular"`、`UIFont.labelFontName = "SpecialElite-Regular"`

- [ ] **Step 1: 書体を取ってくる**

```bash
mkdir -p PhotoKeyboardEx/Fonts
curl -sL -o PhotoKeyboardEx/Fonts/ZenKurenaido-Regular.ttf https://github.com/google/fonts/raw/main/ofl/zenkurenaido/ZenKurenaido-Regular.ttf
curl -sL -o PhotoKeyboardEx/Fonts/OFL-ZenKurenaido.txt https://github.com/google/fonts/raw/main/ofl/zenkurenaido/OFL.txt
curl -sL -o PhotoKeyboardEx/Fonts/SpecialElite-Regular.ttf https://github.com/google/fonts/raw/main/apache/specialelite/SpecialElite-Regular.ttf
curl -sL -o PhotoKeyboardEx/Fonts/LICENSE-SpecialElite.txt https://github.com/google/fonts/raw/main/apache/specialelite/LICENSE.txt
file PhotoKeyboardEx/Fonts/*.ttf
fc-scan --format "%{postscriptname}\n" PhotoKeyboardEx/Fonts/*.ttf 2>/dev/null || true
```
Expected: 2 つとも `TrueType Font data`。PostScript 名が `ZenKurenaido-Regular` と `SpecialElite-Regular` でなければ、実際の名前を報告に書き、以下のコードの名前をそれに合わせる。Special Elite は **Apache License 2.0**（仕様書の「OFL」は誤り。同梱は可能）。

- [ ] **Step 2: 落ちるテストを書く**

アプリテストの `// MARK: - バージョン比較` の直前に足す。

```swift
    // MARK: - 書体

    /// 手書きとタイプライターの書体がアプリに入っていて、名前で引けること
    func testJournalFontsAreBundled() {
        XCTAssertNotNil(UIFont(name: UIFont.journalFontName, size: 14), "Zen Kurenaido が読み込めない")
        XCTAssertNotNil(UIFont(name: UIFont.labelFontName, size: 14), "Special Elite が読み込めない")
        XCTAssertEqual(UIFont.journal(.body).fontName, UIFont.journalFontName)
        XCTAssertEqual(UIFont.label(.caption1).fontName, UIFont.labelFontName)
    }

    /// 文字サイズの設定に追従すること。本文より見出しが大きい
    func testJournalFontsScaleWithTextStyle() {
        XCTAssertGreaterThan(UIFont.journal(.title2).pointSize, UIFont.journal(.footnote).pointSize)
    }
```

Framework テストの `testBrandFontIsRoundedAndHeavy` の直後に足す（Framework のテストはアプリの書体を持たないので、代わりの書体に落ちることをここで確かめる）。

```swift
    /// 書体が読み込めない環境でも、nil にならず代わりの書体が返ること
    func testJournalFontsFallBackWhenMissing() {
        let journal = UIFont.journal(.body)
        let label = UIFont.label(.body)
        XCTAssertGreaterThan(journal.pointSize, 0)
        XCTAssertGreaterThan(label.pointSize, 0)
    }
```

- [ ] **Step 3: 落ちることを確認** — コンパイルエラー（`UIFont.journal` が無い）。

- [ ] **Step 4: 実装**

`Journal.swift` の末尾に足す。

```swift
extension UIFont {
    /// 手書き。題名・メモ・付箋・「次はここ」
    public static let journalFontName = "ZenKurenaido-Regular"
    /// タイプライター。ロゴ・日付・荷札
    public static let labelFontName = "SpecialElite-Regular"

    /// 手書きの書体を、文字サイズの設定に追従する大きさで返す。
    /// 読み込めないとき(キーボード拡張やテスト)は丸ゴシックに落とす
    public static func journal(_ style: UIFont.TextStyle) -> UIFont {
        let size = standardPointSize(for: style)
        guard let font = UIFont(name: journalFontName, size: size) else { return .brand(style) }
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }

    /// タイプライターの書体。読み込めないときは Courier に落とす
    public static func label(_ style: UIFont.TextStyle) -> UIFont {
        let size = standardPointSize(for: style)
        let font = UIFont(name: labelFontName, size: size)
            ?? UIFont(name: "Courier", size: size)
            ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }

    /// 標準の文字サイズ設定での大きさ。UIFontMetrics がここから利用者の設定へ拡大縮小する。
    /// preferredFont の大きさを渡すと、設定の倍率が二重に掛かる
    private static func standardPointSize(for style: UIFont.TextStyle) -> CGFloat {
        UIFont.preferredFont(forTextStyle: style,
                             compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)).pointSize
    }
}
```

書体とライセンスを Resources に登録し、`Info.plist` に足す。

```bash
/usr/libexec/PlistBuddy -c "Add :UIAppFonts array" PhotoKeyboardEx/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :UIAppFonts:0 string ZenKurenaido-Regular.ttf" PhotoKeyboardEx/Info.plist
/usr/libexec/PlistBuddy -c "Add :UIAppFonts:1 string SpecialElite-Regular.ttf" PhotoKeyboardEx/Info.plist
/usr/libexec/PlistBuddy -c "Print :UIAppFonts" PhotoKeyboardEx/Info.plist
```

- [ ] **Step 5: 通ることを確認** — 単一 3 本、アプリ・Framework 全体。
- [ ] **Step 6: コミット** — 件名「手書きとタイプライターの書体を同梱する」

---

### Task 3: 貼った順に並べる（pastedAt）

**Files:**
- Modify: `PhotoKeyboardFramework/Photo.swift`（`pastedAt`、`create` で今の日時を入れる）
- Modify: `PhotoKeyboardFramework/RealmManager.swift:30,38-40,119-129`
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Produces: `RealmPhoto.pastedAt: Date`、`RealmManager.migrationDates(count: Int, endingAt: Date) -> [Date]`（internal static、テスト用に `@testable` で見える）、`realmData` が `pastedAt` の昇順

- [ ] **Step 1: 落ちるテストを書く**

Framework テストの `testSnapshotCanBeOverwritten` の直後に足す。

```swift
    // MARK: - 貼った順

    /// 新しく作った写真には、作った時刻が入ること
    func testNewPhotoRecordsWhenItWasPasted() {
        let before = Date()
        let photo = RealmPhoto.create(id: "p", text: "", image: UIImage(), imageHeight: 1, imageWidth: 1,
                                      getDay: "", isPublic: false, ownerId: "")
        XCTAssertGreaterThanOrEqual(photo.pastedAt.timeIntervalSince1970, before.timeIntervalSince1970 - 1)
    }

    /// 移行で入れる日時は、今の並び順どおりに増えていき、最後が基準の時刻になること
    func testMigrationDatesKeepTheCurrentOrder() {
        let end = Date(timeIntervalSince1970: 1_800_000_000)
        let dates = RealmManager.migrationDates(count: 3, endingAt: end)
        XCTAssertEqual(dates.count, 3)
        XCTAssertLessThan(dates[0], dates[1])
        XCTAssertLessThan(dates[1], dates[2])
        XCTAssertEqual(dates[2], end)
    }

    /// 並びは pastedAt の昇順。途中を消しても残りの順番は変わらない
    func testPhotosStayInPastedOrderAfterDeletingOne() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("order-\(UUID().uuidString).realm")
        let realm = try makeRealm(at: url)
        try realm.write {
            for (i, id) in ["a", "b", "c", "d"].enumerated() {
                let p = RealmPhoto.create(id: id, text: "", image: UIImage(), imageHeight: 1, imageWidth: 1,
                                          getDay: "", isPublic: false, ownerId: "")
                p.pastedAt = Date(timeIntervalSince1970: TimeInterval(1000 + i))
                realm.add(p)
            }
        }
        try realm.write { realm.delete(realm.objects(RealmPhoto.self).filter("id == 'b'")) }
        let ids = Array(realm.objects(RealmPhoto.self).sorted(byKeyPath: RealmManager.orderKey).map { $0.id })
        XCTAssertEqual(ids, ["a", "c", "d"])
    }
```

（`makeRealm(at:)` は既存ヘルパー。スキーマ版を指定していなければ、ヘルパーの `Realm.Configuration` に `schemaVersion` を足さずに済むよう、新しい一時ファイルを使う）

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー（`pastedAt` が無い）。

- [ ] **Step 3: 実装**

`Photo.swift` の `ownerId` の直後:
```swift
    /// ノートに貼った時刻。マイボードはこの順に上から下へ並ぶ。
    /// Realm は並びを指定しないと、削除のあとに順番が入れ替わることがある
    @objc public dynamic var pastedAt = Date()
```
`create` の末尾（`return` の前）に `realmPhoto.pastedAt = Date()`。

`RealmManager.swift`:
```swift
    private static let schemaVersion: UInt64 = 2
    /// マイボードとキーボードの並び順
    static let orderKey = "pastedAt"

    public var realmData: Results<RealmPhoto> {
        return realm().objects(RealmPhoto.self).sorted(byKeyPath: RealmManager.orderKey)
    }

    /// 版 1 から上げるときに既存の写真へ入れる日時。
    /// 今見えている順番を変えないよう、1 秒ずつ増やして最後を基準の時刻にする
    static func migrationDates(count: Int, endingAt end: Date) -> [Date] {
        return (0..<count).map { end.addingTimeInterval(TimeInterval($0 - (count - 1))) }
    }
```
`makeConfiguration` の `migrationBlock`:
```swift
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
```

`importPhotos`（旧ファイルからの取り込み）と `RealmBackup` の復元は `create(value:)` で全項目を写すので変更不要。版 1 の旧ファイルを開くときも同じ移行が走る。

- [ ] **Step 4: 通ることを確認** — 単一 3 本、Framework とアプリ全体（キーボード拡張も `realmData` を使うが、並びが「挿入順」→「貼った順」になるだけで同じ意味）。
- [ ] **Step 5: コミット** — 件名「貼った時刻を持たせ、並びを安定させる」

---

### Task 4: 動きと振動を持ち込む

**Files:**
- Create: `PhotoKeyboardFramework/Motion.swift`（`PhotoKeyboardFramework` ターゲット）
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Produces:
  - `Motion.isReducedOverride: Bool?`、`Motion.isReduced: Bool`
  - `Motion.pressDown(_ view: UIView)`、`Motion.release(_ view: UIView)`（押下の縮みは `view.transform` に**掛け合わせる**。回転している写真やシールでも角度を保つ）
  - `Motion.paste(_ view: UIView, to final: CGAffineTransform, completion: (() -> Void)?)`（上から 40pt 落ちて少し回りながら `final` に収まる。視差効果を減らす設定ならフェードだけで `final` を置く）
  - `Haptic.Kind { tap, paste, full }`、`protocol HapticDriver`、`Haptic.driver`、`Haptic.play(_:)`

- [ ] **Step 1: 落ちるテストを書く**

`testAllSymbolsExist` の直後に足す。

```swift
    // MARK: - 動きと振動

    private final class RecordingHaptic: HapticDriver {
        var played: [Haptic.Kind] = []
        func play(_ kind: Haptic.Kind) { played.append(kind) }
    }

    /// 押すと縮み、離すと元の角度のまま戻ること。回転した写真でも角度が消えない
    @MainActor
    func testPressKeepsRotation() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let tilted = CGAffineTransform(rotationAngle: 0.1)
        view.transform = tilted
        Motion.pressDown(view)
        XCTAssertLessThan(hypot(view.transform.a, view.transform.b), 1.0, "押しても縮んでいない")
        XCTAssertEqual(atan2(view.transform.b, view.transform.a), 0.1, accuracy: 0.001, "押したら角度が消えた")
        Motion.release(view)
        XCTAssertEqual(view.transform, tilted, "離しても元に戻らない")
    }

    /// 貼る動きは最後に指定の姿勢で止まること
    @MainActor
    func testPasteEndsAtFinalTransform() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let final = CGAffineTransform(rotationAngle: -0.12)
        let done = expectation(description: "貼り終わり")
        Motion.paste(view, to: final) { done.fulfill() }
        wait(for: [done], timeout: 3)
        XCTAssertEqual(view.transform, final)
        XCTAssertEqual(view.alpha, 1, accuracy: 0.001)
    }

    /// 視差効果を減らす設定では、落ちも回りもせず、はじめから最後の姿勢にいること
    @MainActor
    func testPasteSkipsMovementWhenReduced() {
        Motion.isReducedOverride = true
        defer { Motion.isReducedOverride = nil }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let final = CGAffineTransform(rotationAngle: 0.05)
        Motion.paste(view, to: final, completion: nil)
        XCTAssertEqual(view.transform, final)
    }

    /// 振動は差し替えた生成器へ届くこと
    func testHapticGoesThroughInjectedDriver() {
        let recorder = RecordingHaptic()
        let previous = Haptic.driver
        Haptic.driver = recorder
        defer { Haptic.driver = previous }
        Haptic.play(.tap)
        Haptic.play(.full)
        XCTAssertEqual(recorder.played, [.tap, .full])
    }
```

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー（`Motion` が無い）。

- [ ] **Step 3: 実装**

```swift
//
//  Motion.swift
//  PhotoKeyboardFramework
//
//  押す・貼るの動きと振動。時間とバネはここでだけ決める。
//  「視差効果を減らす」が有効なら、移動と回転をせずフェードだけにする。
//

import UIKit

public enum Motion {
    /// テストから設定を固定するための上書き。nil なら端末の設定に従う
    public static var isReducedOverride: Bool?

    public static var isReduced: Bool {
        return isReducedOverride ?? UIAccessibility.isReduceMotionEnabled
    }

    static let pressDuration: TimeInterval = 0.12
    static let pressScale: CGFloat = 0.96
    static let pasteDrop: CGFloat = 40
    static let pasteSpin: CGFloat = 0.14
    static let pasteDuration: TimeInterval = 0.55

    /// 押している間の姿勢。押す前の姿勢を覚えておき、離したらそこへ戻す
    private static var restingTransforms: [ObjectIdentifier: CGAffineTransform] = [:]

    /// 押した瞬間。いまの姿勢(回転を含む)に縮みを掛け合わせる
    public static func pressDown(_ view: UIView) {
        guard !isReduced else { return }
        let resting = view.transform
        restingTransforms[ObjectIdentifier(view)] = resting
        UIView.animate(withDuration: pressDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            view.transform = resting.scaledBy(x: pressScale, y: pressScale)
        }
    }

    /// 離した瞬間。押す前の姿勢へバネで戻す
    public static func release(_ view: UIView) {
        guard !isReduced else { return }
        let resting = restingTransforms.removeValue(forKey: ObjectIdentifier(view)) ?? .identity
        UIView.animate(withDuration: pressDuration * 3, delay: 0, usingSpringWithDamping: 0.55,
                       initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            view.transform = resting
        }
    }

    /// 貼る。テープごと上から落ちてきて、少し回りながら所定の姿勢で止まる
    public static func paste(_ view: UIView, to final: CGAffineTransform, completion: (() -> Void)?) {
        if isReduced {
            view.transform = final
            view.alpha = 0
            UIView.animate(withDuration: 0.25, animations: { view.alpha = 1 }) { _ in completion?() }
            return
        }
        view.alpha = 0
        view.transform = final.translatedBy(x: 0, y: -pasteDrop).rotated(by: pasteSpin)
        UIView.animate(withDuration: pasteDuration, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.2, options: [.curveEaseOut]) {
            view.transform = final
            view.alpha = 1
        } completion: { _ in completion?() }
    }
}

/// 振動の生成器。テストでは記録用に差し替える
public protocol HapticDriver {
    func play(_ kind: Haptic.Kind)
}

final class SystemHapticDriver: HapticDriver {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    func play(_ kind: Haptic.Kind) {
        switch kind {
        case .tap: light.impactOccurred()
        case .paste: medium.impactOccurred()
        case .full: notification.notificationOccurred(.success)
        }
    }
}

/// 振動の種類。音は入れない
public enum Haptic {
    public enum Kind: Equatable {
        /// 押した
        case tap
        /// 写真を貼った
        case paste
        /// ノートがいっぱいになった
        case full
    }

    public static var driver: HapticDriver = SystemHapticDriver()

    public static func play(_ kind: Kind) {
        driver.play(kind)
    }
}
```

- [ ] **Step 4: 通ることを確認** — 単一 4 本、Framework 全体。
- [ ] **Step 5: コミット** — 件名「押す・貼る動きと振動を部品にする」

---

### Task 5: 貼り方を決める（JournalPlacer）

**Files:**
- Create: `PhotoKeyboardEx/Journal/JournalPlacer.swift`（`PhotoKeyboardEx` ターゲット、グループ `PhotoKeyboardEx/Journal`、`path = Journal`）
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Produces（すべて internal。UIKit は `CGRect` / `CGFloat` のためだけに `import CoreGraphics`）:

```swift
enum PrintShape: Equatable { case print, polaroid, torn, landscape }
enum TapeStyle: Equatable { case black, white, clear, long, corners, clip }
enum JournalProp: Equatable { case none, ticket, star }
enum CaptionSide: Equatable { case beside, below }

struct JournalItemInput: Equatable {
    let id: String
    /// 画像の幅 / 高さ。0 以下なら 1 とみなす
    let aspectRatio: CGFloat
    /// 貼った日("yyyy-MM-dd")。日付が変わった最初の 1 枚に荷札を付ける
    let dayKey: String
}

struct JournalPlacement: Equatable {
    /// 回転前の写真の枠(ポラロイドの白い縁を含む)
    let frame: CGRect
    /// 回転(ラジアン)
    let angle: CGFloat
    let shape: PrintShape
    let tape: TapeStyle
    let prop: JournalProp
    /// 題名の枠と回転
    let captionFrame: CGRect
    let captionAngle: CGFloat
    let captionSide: CaptionSide
    /// 写真と題名を合わせた下端。次の写真はここから置く
    let bottom: CGFloat
    /// 写真が左右どちらに寄っているか(true なら左)
    let isLeft: Bool
}

enum JournalPlacer {
    static let margin: CGFloat = 16
    static let captionMinWidth: CGFloat = 110
    static let maxAngleDegrees: CGFloat = 9
    static let maxOverlap: CGFloat = 0.2
    static func fnv1a64(_ string: String) -> UInt64
    static func place(_ items: [JournalItemInput], width: CGFloat, top: CGFloat) -> [JournalPlacement]
    /// 最後の写真の下に置く「次はここ」の枠と回転
    static func nextSpot(after placements: [JournalPlacement], width: CGFloat, top: CGFloat) -> (frame: CGRect, angle: CGFloat)
}
```

- [ ] **Step 1: 落ちるテストを書く**

アプリテストの `// MARK: - バージョン比較` の直前に足す。

```swift
    // MARK: - 貼り方

    private func inputs(_ count: Int, prefix: String = "photo") -> [JournalItemInput] {
        (0..<count).map { JournalItemInput(id: "\(prefix)-\($0)", aspectRatio: 1, dayKey: "2026-09-27") }
    }

    /// FNV-1a は既知の値と一致すること。hashValue と違い起動をまたいで変わらない
    func testFnv1aMatchesKnownVectors() {
        XCTAssertEqual(JournalPlacer.fnv1a64(""), 0xcbf29ce484222325)
        XCTAssertEqual(JournalPlacer.fnv1a64("a"), 0xaf63dc4c8601ec8c)
        XCTAssertEqual(JournalPlacer.fnv1a64("foobar"), 0x85944171f73967e8)
    }

    /// 同じ写真の列なら、何度計算しても同じ貼り方になること
    func testPlacementIsDeterministic() {
        let a = JournalPlacer.place(inputs(8), width: 390, top: 0)
        let b = JournalPlacer.place(inputs(8), width: 390, top: 0)
        XCTAssertEqual(a, b)
    }

    /// 1 枚足しても、それまでの写真の枠と角度が変わらないこと
    func testAddingAPhotoDoesNotMoveEarlierOnes() {
        let seven = JournalPlacer.place(inputs(7), width: 390, top: 0)
        let eight = JournalPlacer.place(inputs(8), width: 390, top: 0)
        XCTAssertEqual(Array(eight.prefix(7)), seven)
    }

    /// 角度は ±9° 以内、回転後の外形はノートの幅に収まること
    func testPlacementStaysInsideTheNotebook() {
        let width: CGFloat = 375
        for p in JournalPlacer.place(inputs(40), width: width, top: 0) {
            XCTAssertLessThanOrEqual(abs(p.angle), JournalPlacer.maxAngleDegrees * .pi / 180 + 0.0001)
            let rotated = p.frame.applying(CGAffineTransform(translationX: -p.frame.midX, y: -p.frame.midY)
                .rotated(by: p.angle).translatedBy(x: p.frame.midX, y: p.frame.midY))
            XCTAssertGreaterThanOrEqual(rotated.minX, 0, "左にはみ出した: \(p)")
            XCTAssertLessThanOrEqual(rotated.maxX, width, "右にはみ出した: \(p)")
            XCTAssertGreaterThanOrEqual(p.captionFrame.minX, 0)
            XCTAssertLessThanOrEqual(p.captionFrame.maxX, width)
        }
    }

    /// 前の写真への食い込みは、前の写真の高さの 20% 以下
    func testOverlapIsLimited() {
        let placements = JournalPlacer.place(inputs(40), width: 390, top: 0)
        for (prev, next) in zip(placements, placements.dropFirst()) {
            let overlap = prev.frame.maxY - next.frame.minY
            XCTAssertLessThanOrEqual(overlap, prev.frame.height * JournalPlacer.maxOverlap + 0.5)
        }
    }

    /// 写真は左右を行き来すること。整った 1 列にしない
    func testPhotosAlternateSides() {
        let placements = JournalPlacer.place(inputs(6), width: 390, top: 0)
        XCTAssertEqual(placements.map(\.isLeft), [true, false, true, false, true, false])
    }

    /// 形の出方はおおむね 紙焼き 40 / ポラロイド 25 / 切れ端 20 / 横長 15
    func testShapesAppearInTheIntendedMix() {
        let placements = JournalPlacer.place(inputs(1000, prefix: "mix"), width: 390, top: 0)
        func ratio(_ s: PrintShape) -> Double { Double(placements.filter { $0.shape == s }.count) / 1000 }
        XCTAssertEqual(ratio(.print), 0.40, accuracy: 0.06)
        XCTAssertEqual(ratio(.polaroid), 0.25, accuracy: 0.06)
        XCTAssertEqual(ratio(.torn), 0.20, accuracy: 0.06)
        XCTAssertEqual(ratio(.landscape), 0.15, accuracy: 0.06)
    }

    /// 日付が変わった最初の 1 枚に荷札が付くこと
    func testTicketMarksTheFirstPhotoOfEachDay() {
        let items = [
            JournalItemInput(id: "x1", aspectRatio: 1, dayKey: "2026-09-25"),
            JournalItemInput(id: "x2", aspectRatio: 1, dayKey: "2026-09-25"),
            JournalItemInput(id: "x3", aspectRatio: 1, dayKey: "2026-09-27"),
        ]
        let props = JournalPlacer.place(items, width: 390, top: 0).map(\.prop)
        XCTAssertEqual(props[0], .ticket)
        XCTAssertNotEqual(props[1], .ticket)
        XCTAssertEqual(props[2], .ticket)
    }

    /// 「次はここ」は最後の写真より下にあり、ノートの幅に収まること
    func testNextSpotSitsBelowTheLastPhoto() {
        let placements = JournalPlacer.place(inputs(3), width: 390, top: 0)
        let spot = JournalPlacer.nextSpot(after: placements, width: 390, top: 0)
        XCTAssertGreaterThan(spot.frame.minY, placements.last!.bottom)
        XCTAssertGreaterThanOrEqual(spot.frame.minX, 0)
        XCTAssertLessThanOrEqual(spot.frame.maxX, 390)
        let empty = JournalPlacer.nextSpot(after: [], width: 390, top: 24)
        XCTAssertGreaterThanOrEqual(empty.frame.minY, 24)
    }
```

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー。

- [ ] **Step 3: 実装**

```swift
//
//  JournalPlacer.swift
//  PhotoKeyboardEx
//
//  写真の id から、ノートへの貼り方(形・大きさ・角度・テープ・位置)を決める。
//  乱数を使わないので、同じ写真はいつ開いても同じ場所に同じ貼り方で出る。
//  Realm も UIKit も知らない。
//

import CoreGraphics

enum PrintShape: Equatable { case print, polaroid, torn, landscape }
enum TapeStyle: Equatable { case black, white, clear, long, corners, clip }
enum JournalProp: Equatable { case none, ticket, star }
enum CaptionSide: Equatable { case beside, below }

struct JournalItemInput: Equatable {
    let id: String
    let aspectRatio: CGFloat
    let dayKey: String
}

struct JournalPlacement: Equatable {
    let frame: CGRect
    let angle: CGFloat
    let shape: PrintShape
    let tape: TapeStyle
    let prop: JournalProp
    let captionFrame: CGRect
    let captionAngle: CGFloat
    let captionSide: CaptionSide
    let bottom: CGFloat
    let isLeft: Bool
}

enum JournalPlacer {
    static let margin: CGFloat = 16
    static let captionMinWidth: CGFloat = 110
    static let captionMaxWidth: CGFloat = 150
    static let captionHeightBeside: CGFloat = 64
    static let captionHeightBelow: CGFloat = 44
    static let maxAngleDegrees: CGFloat = 9
    static let maxOverlap: CGFloat = 0.2
    static let gap: CGFloat = 10
    static let sizeTiers: [CGFloat] = [0.62, 0.50, 0.40]
    static let tapes: [TapeStyle] = [.black, .white, .clear, .long, .corners, .clip]

    /// FNV-1a 64 ビット。Swift の hashValue は起動ごとに変わるので使わない
    static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    static func place(_ items: [JournalItemInput], width: CGFloat, top: CGFloat) -> [JournalPlacement] {
        var result: [JournalPlacement] = []
        var previous: JournalPlacement?
        var previousDay: String?
        for (index, item) in items.enumerated() {
            let h = fnv1a64(item.id)
            let shape = shape(for: h)
            let photoWidth = (width * sizeTiers[Int((h >> 8) % 3)]).rounded()
            let height = photoHeight(width: photoWidth, shape: shape, aspectRatio: item.aspectRatio)
            let angle = (-maxAngleDegrees + CGFloat((h >> 16) % 37) * 0.5) * .pi / 180
            let tape = tapes[Int((h >> 24) % UInt64(tapes.count))]
            let jitter = CGFloat(Int((h >> 32) % 25) - 12)
            let overlap = CGFloat((h >> 40) % 21) / 100
            let isLeft = index % 2 == 0

            // 回転しても幅に収まるよう、回転後の外形の半幅で左右を詰める
            let halfSpan = (photoWidth * abs(cos(angle)) + height * abs(sin(angle))) / 2
            let preferredMidX = isLeft ? margin + photoWidth / 2 + jitter : width - margin - photoWidth / 2 + jitter
            let midX = min(max(preferredMidX, halfSpan), width - halfSpan)

            let y: CGFloat
            if let previous = previous {
                y = previous.bottom - previous.frame.height * overlap + (overlap == 0 ? gap : 0)
            } else {
                y = top
            }
            let frame = CGRect(x: midX - photoWidth / 2, y: y, width: photoWidth, height: height)

            // 題名は空いている側へ。狭ければ写真の下
            let freeWidth = isLeft ? width - (midX + halfSpan) - margin : (midX - halfSpan) - margin
            let captionSide: CaptionSide = freeWidth >= captionMinWidth ? .beside : .below
            let captionFrame: CGRect
            if captionSide == .beside {
                let w = min(freeWidth, captionMaxWidth)
                let x = isLeft ? midX + halfSpan + 8 : midX - halfSpan - 8 - w
                captionFrame = CGRect(x: x, y: frame.minY + height * 0.3, width: w, height: captionHeightBeside)
            } else {
                let w = min(width - margin * 2, photoWidth + 40)
                let x = min(max(midX - w / 2, margin), width - margin - w)
                captionFrame = CGRect(x: x, y: frame.maxY + 8, width: w, height: captionHeightBelow)
            }
            let captionAngle = -angle / 3

            let prop: JournalProp
            if item.dayKey != previousDay {
                prop = .ticket
            } else {
                prop = (h >> 48) % 5 == 0 ? .star : .none
            }

            let placement = JournalPlacement(frame: frame, angle: angle, shape: shape, tape: tape, prop: prop,
                                             captionFrame: captionFrame, captionAngle: captionAngle,
                                             captionSide: captionSide,
                                             bottom: max(frame.maxY + halfSpanVerticalSlack(angle, photoWidth, height),
                                                         captionFrame.maxY),
                                             isLeft: isLeft)
            result.append(placement)
            previous = placement
            previousDay = item.dayKey
        }
        return result
    }

    static func nextSpot(after placements: [JournalPlacement], width: CGFloat, top: CGFloat) -> (frame: CGRect, angle: CGFloat) {
        let w = (width * 0.45).rounded()
        let h = (w * 0.8).rounded()
        let isLeft = !(placements.last?.isLeft ?? false)
        let x = isLeft ? margin + 12 : width - margin - 12 - w
        let y = (placements.last?.bottom ?? top) + 20
        let angle: CGFloat = (isLeft ? -7 : 6) * .pi / 180
        return (CGRect(x: x, y: y, width: w, height: h), angle)
    }

    private static func shape(for hash: UInt64) -> PrintShape {
        switch hash % 100 {
        case 0..<40: return .print
        case 40..<65: return .polaroid
        case 65..<85: return .torn
        default: return .landscape
        }
    }

    private static func photoHeight(width: CGFloat, shape: PrintShape, aspectRatio: CGFloat) -> CGFloat {
        switch shape {
        case .landscape: return (width / 1.5).rounded()
        case .polaroid: return (width * 1.18).rounded()
        case .print, .torn:
            let ratio = min(max(aspectRatio > 0 ? aspectRatio : 1, 0.75), 1.33)
            return (width / ratio).rounded()
        }
    }

    /// 回転で下にはみ出すぶん。次の写真がここに潜り込まないよう下端に足す
    private static func halfSpanVerticalSlack(_ angle: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGFloat {
        let rotatedHeight = w * abs(sin(angle)) + h * abs(cos(angle))
        return max((rotatedHeight - h) / 2, 0)
    }
}
```

`testOverlapIsLimited` は回転前の枠で測っている。`bottom` に回転ぶんの余りを足しているため、枠同士の食い込みは 20% より小さくなる（テストは上限だけを見る）。

- [ ] **Step 4: 通ることを確認** — 単一 9 本、アプリ全体。`testShapesAppearInTheIntendedMix` が許容差を外れたら、`shape(for:)` の区切りではなく **入力の id の作り方**（"mix-0"〜"mix-999"）で偏っていないかを確認し、区切りは仕様の割合のまま変えない。どうしても外れる場合は許容差を 0.08 まで広げ、実測の割合を報告に書く。
- [ ] **Step 5: コミット** — 件名「写真の id から貼り方を決める」

---

### Task 6: 紙とテープと小物を描く（JournalProps）

**Files:**
- Create: `PhotoKeyboardEx/Journal/JournalProps.swift`
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Consumes: `TapeStyle`（Task 5）、色トークン（Task 1）
- Produces:
  - `final class PaperBackgroundView: UIView`（方眼。`gridSpacing: CGFloat = 14`）
  - `final class TapeView: UIView`（`init(style: TapeStyle)`、`style` が `.corners` / `.clip` のときは使わない）
  - `final class ClipView: UIView`（ゼムクリップの線画）
  - `final class TicketView: UIView`（`text: String`、荷札の形、`UIFont.label(.caption2)`）
  - `final class StarStickerView: UIView`
  - `enum TornEdge { static func mask(for bounds: CGRect) -> CAShapeLayer }`（上辺がぎざぎざ）

- [ ] **Step 1: 落ちるテストを書く**

アプリテストに、既存の `containsColor(_:_:tolerance:)` ヘルパーを使って足す（`// MARK: - 貼り方` の後）。

```swift
    // MARK: - 紙とテープ

    /// 方眼の紙は、紙の色と線の色の両方を描くこと
    @MainActor
    func testPaperDrawsGridLines() {
        let paper = PaperBackgroundView(frame: CGRect(x: 0, y: 0, width: 140, height: 140))
        paper.overrideUserInterfaceStyle = .light
        paper.layoutIfNeeded()
        XCTAssertTrue(containsColor(paper, UIColor.bgBase.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)), tolerance: 3))
        // 線は紙より少し暗い。紙そのものの色以外の画素があること
        XCTAssertTrue(containsColor(paper, UIColor(red: 0.90, green: 0.90, blue: 0.91, alpha: 1), tolerance: 20), "方眼の線が描かれていない")
    }

    /// テープは種類ごとの色で描かれること(黒テープはライトで黒)
    @MainActor
    func testBlackTapeIsDark() {
        let tape = TapeView(style: .black)
        tape.frame = CGRect(x: 0, y: 0, width: 60, height: 18)
        tape.overrideUserInterfaceStyle = .light
        XCTAssertTrue(containsColor(tape, UIColor(red: 0.11, green: 0.106, blue: 0.098, alpha: 1), tolerance: 30))
    }

    /// ちぎった切れ端のマスクは、上辺がまっすぐでないこと
    func testTornEdgeIsJagged() {
        let mask = TornEdge.mask(for: CGRect(x: 0, y: 0, width: 200, height: 200))
        guard let path = mask.path else { return XCTFail("マスクが無い") }
        var topYs: Set<Int> = []
        path.applyWithBlock { element in
            let p = element.pointee.points[0]
            if p.y < 10 { topYs.insert(Int(p.y.rounded())) }
        }
        XCTAssertGreaterThan(topYs.count, 1, "上辺が一直線")
    }

    /// 荷札はタイプライターの書体で日付を載せること
    @MainActor
    func testTicketUsesLabelFont() {
        let ticket = TicketView()
        ticket.text = "2026.09.27"
        XCTAssertEqual(ticket.textLabelForTesting.font.fontName, UIFont.label(.caption2).fontName)
        XCTAssertEqual(ticket.textLabelForTesting.text, "2026.09.27")
    }
```

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー。

- [ ] **Step 3: 実装**

```swift
//
//  JournalProps.swift
//  PhotoKeyboardEx
//
//  ノートの紙と、写真を留める文房具。実在するものだけを描く。
//  画像は持たず、すべて描画で作る(ダークでも色トークンで追従する)。
//

import UIKit
import PhotoKeyboardFramework

/// 方眼ノートの紙
final class PaperBackgroundView: UIView {
    static let gridSpacing: CGFloat = 14

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        contentMode = .redraw
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIColor.bgBase.setFill()
        context.fill(rect)
        UIColor.paperGrid.setStroke()
        context.setLineWidth(1 / max(window?.screen.scale ?? 2, 1))
        let spacing = PaperBackgroundView.gridSpacing
        var x = (rect.minX / spacing).rounded(.down) * spacing
        while x <= rect.maxX {
            context.move(to: CGPoint(x: x, y: rect.minY)); context.addLine(to: CGPoint(x: x, y: rect.maxY)); x += spacing
        }
        var y = (rect.minY / spacing).rounded(.down) * spacing
        while y <= rect.maxY {
            context.move(to: CGPoint(x: rect.minX, y: y)); context.addLine(to: CGPoint(x: rect.maxX, y: y)); y += spacing
        }
        context.strokePath()
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        setNeedsDisplay()
    }
}

/// マスキングテープ。黒・白・透明・長い
final class TapeView: UIView {
    let style: TapeStyle

    init(style: TapeStyle) {
        self.style = style
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        applyColor()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyColor() {
        switch style {
        case .black, .long: backgroundColor = UIColor.accent.withAlphaComponent(0.9)
        case .white: backgroundColor = .tapeWhite
        case .clear:
            backgroundColor = .tapeClear
            layer.borderWidth = 0.5
            layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        case .corners, .clip: backgroundColor = UIColor.accent.withAlphaComponent(0.9)
        }
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        applyColor()
    }
}

/// ゼムクリップ
final class ClipView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let outer = UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: rect.width / 2)
        let inner = UIBezierPath(roundedRect: rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.14),
                                 cornerRadius: rect.width / 3)
        UIColor.pencil.setStroke()
        outer.lineWidth = 1.6
        inner.lineWidth = 1.6
        outer.stroke()
        inner.stroke()
    }
}

/// 荷札。左端が尖り、穴が開いている
final class TicketView: UIView {
    private let label = UILabel()
    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }
    var textLabelForTesting: UILabel { label }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .kraft
        isUserInteractionEnabled = false
        label.font = .label(.caption2)
        label.textColor = UIColor(red: 0.23, green: 0.18, blue: 0.12, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    convenience init() { self.init(frame: .zero) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 6, y: 0))
        path.addLine(to: CGPoint(x: bounds.maxX, y: 0))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 6, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 0, y: bounds.midY))
        path.close()
        path.append(UIBezierPath(ovalIn: CGRect(x: 6, y: bounds.midY - 2, width: 4, height: 4)).reversing())
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

/// 星のシール
final class StarStickerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .kraft
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let points: [CGPoint] = [(0.5, 0), (0.61, 0.35), (0.98, 0.35), (0.68, 0.57), (0.79, 0.91),
                                 (0.5, 0.7), (0.21, 0.91), (0.32, 0.57), (0.02, 0.35), (0.39, 0.35)]
            .map { CGPoint(x: $0.0 * bounds.width, y: $0.1 * bounds.height) }
        let path = UIBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.close()
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

/// ちぎった切れ端の形
enum TornEdge {
    static func mask(for bounds: CGRect) -> CAShapeLayer {
        let steps: [CGFloat] = [0.03, 0, 0.02, 0, 0.03, 0, 0.02, 0, 0.03]
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.height * steps[0]))
        for (i, ratio) in steps.enumerated() {
            let x = bounds.width * CGFloat(i) / CGFloat(steps.count - 1)
            path.addLine(to: CGPoint(x: x, y: bounds.height * ratio))
        }
        path.addLine(to: CGPoint(x: bounds.maxX * 0.98, y: bounds.maxY))
        path.addLine(to: CGPoint(x: 0, y: bounds.maxY * 0.98))
        path.close()
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        return layer
    }
}
```

- [ ] **Step 4: 通ることを確認** — 単一 4 本、アプリ全体。`testPaperDrawsGridLines` の線の色の期待値が合わない場合は、描画結果の実際の線の画素値を報告に書き、テストの期待値を「紙の色と 4 以上違う画素が存在する」に書き換える（意図は「線が描かれていること」）。
- [ ] **Step 5: コミット** — 件名「方眼の紙とテープと小物を描く」

---

### Task 7: ノートのレイアウト（JournalLayout）

**Files:**
- Create: `PhotoKeyboardEx/Journal/JournalLayout.swift`
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Consumes: `JournalPlacer.place` / `nextSpot`、`JournalItemInput`、`JournalPlacement`（Task 5）
- Produces:

```swift
final class JournalLayout: UICollectionViewLayout {
    static let captionKind = "JournalCaption"
    static let headerKind = "JournalHeader"
    static let headerHeight: CGFloat = 28
    static let bottomClearance: CGFloat = 140   // 追加ボタンの下に隠れないぶん
    /// セクション 0 の写真。呼ばれるたびに最新を返すこと
    var itemsProvider: () -> [JournalItemInput] = { [] }
    /// 計算済みの貼り方(セルが形とテープを知るために使う)
    private(set) var placements: [JournalPlacement] = []
}
```
- セクション 0: 写真。`indexPath.item` 番目に `placements[item]`
- セクション 1: 「次はここ / いっぱい」のセル 1 つ（セクション 1 の項目数は呼び出し側が 1 にする）
- 補助ビュー: `headerKind` をセクション 0 の頭に 1 つ、`captionKind` を写真ごとに 1 つ

- [ ] **Step 1: 落ちるテストを書く**

```swift
    // MARK: - ノートのレイアウト

    /// レイアウトに渡すだけの最小のデータソース
    private final class StubSource: NSObject, UICollectionViewDataSource {
        var photoCount: Int
        init(photoCount: Int) { self.photoCount = photoCount }
        func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }
        func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { section == 0 ? photoCount : 1 }
        func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
            cv.dequeueReusableCell(withReuseIdentifier: "c", for: ip)
        }
        func collectionView(_ cv: UICollectionView, viewForSupplementaryElementOfKind kind: String, at ip: IndexPath) -> UICollectionReusableView {
            cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "s", for: ip)
        }
    }

    @MainActor
    private func makeJournal(photoCount: Int, width: CGFloat = 390) -> (UICollectionView, JournalLayout, StubSource) {
        let layout = JournalLayout()
        layout.itemsProvider = { (0..<photoCount).map { JournalItemInput(id: "L\($0)", aspectRatio: 1, dayKey: "2026-09-27") } }
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: width, height: 800), collectionViewLayout: layout)
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "c")
        cv.register(UICollectionReusableView.self, forSupplementaryViewOfKind: JournalLayout.captionKind, withReuseIdentifier: "s")
        cv.register(UICollectionReusableView.self, forSupplementaryViewOfKind: JournalLayout.headerKind, withReuseIdentifier: "s")
        let source = StubSource(photoCount: photoCount)
        cv.dataSource = source
        cv.layoutIfNeeded()
        return (cv, layout, source)
    }

    /// 写真の姿勢は貼り方の角度どおりに回っていること
    @MainActor
    func testLayoutRotatesEachPhoto() {
        let (cv, layout, _) = makeJournal(photoCount: 3)
        for i in 0..<3 {
            let attrs = cv.layoutAttributesForItem(at: IndexPath(item: i, section: 0))!
            XCTAssertEqual(atan2(attrs.transform.b, attrs.transform.a), layout.placements[i].angle, accuracy: 0.0001)
            XCTAssertEqual(attrs.center.x, layout.placements[i].frame.midX, accuracy: 0.5)
        }
    }

    /// 後から貼った写真ほど上に重なること
    @MainActor
    func testLaterPhotosSitOnTop() {
        let (cv, _, _) = makeJournal(photoCount: 3)
        let z = (0..<3).map { cv.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))!.zIndex }
        XCTAssertEqual(z, z.sorted())
        XCTAssertLessThan(z[0], z[2])
    }

    /// 「次はここ」はいちばん下で、ノートの高さはその下に追加ボタンのぶんの余白を持つこと
    @MainActor
    func testNextSpotIsLastAndContentLeavesRoomForTheButton() {
        let (cv, layout, _) = makeJournal(photoCount: 4)
        let spot = cv.layoutAttributesForItem(at: IndexPath(item: 0, section: 1))!
        let lastPhoto = cv.layoutAttributesForItem(at: IndexPath(item: 3, section: 0))!
        XCTAssertGreaterThan(spot.frame.minY, lastPhoto.center.y)
        XCTAssertGreaterThanOrEqual(layout.collectionViewContentSize.height, spot.frame.maxY + JournalLayout.bottomClearance - 1)
        XCTAssertEqual(layout.collectionViewContentSize.width, 390, accuracy: 0.5)
    }

    /// 題名の補助ビューが写真ごとにあり、日付の見出しが頭にあること
    @MainActor
    func testCaptionsAndHeaderAreLaidOut() {
        let (cv, layout, _) = makeJournal(photoCount: 2)
        XCTAssertNotNil(layout.layoutAttributesForSupplementaryView(ofKind: JournalLayout.headerKind, at: IndexPath(item: 0, section: 0)))
        for i in 0..<2 {
            let caption = layout.layoutAttributesForSupplementaryView(ofKind: JournalLayout.captionKind, at: IndexPath(item: i, section: 0))
            XCTAssertEqual(caption?.center.x ?? -1, layout.placements[i].captionFrame.midX, accuracy: 0.5)
        }
        XCTAssertEqual(layout.layoutAttributesForElements(in: CGRect(x: 0, y: 0, width: 390, height: 100_000))?.count, 2 + 2 + 1 + 1)
        _ = cv
    }

    /// 写真が 0 枚でも「次はここ」が見出しの下に出ること
    @MainActor
    func testEmptyNotebookStillShowsNextSpot() {
        let (cv, _, _) = makeJournal(photoCount: 0)
        let spot = cv.layoutAttributesForItem(at: IndexPath(item: 0, section: 1))!
        XCTAssertGreaterThanOrEqual(spot.frame.minY, JournalLayout.headerHeight)
    }
```

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー。

- [ ] **Step 3: 実装**

```swift
//
//  JournalLayout.swift
//  PhotoKeyboardEx
//
//  ノートの並べ方。貼り方は JournalPlacer が決め、ここはそれを枠と回転に変えるだけ。
//  セクション 0 が写真、セクション 1 が「次はここ」の 1 マス。
//

import UIKit

final class JournalLayout: UICollectionViewLayout {
    static let captionKind = "JournalCaption"
    static let headerKind = "JournalHeader"
    static let headerHeight: CGFloat = 28
    static let bottomClearance: CGFloat = 140

    var itemsProvider: () -> [JournalItemInput] = { [] }
    private(set) var placements: [JournalPlacement] = []

    private var itemAttributes: [UICollectionViewLayoutAttributes] = []
    private var captionAttributes: [UICollectionViewLayoutAttributes] = []
    private var headerAttributes: UICollectionViewLayoutAttributes?
    private var spotAttributes: UICollectionViewLayoutAttributes?
    private var contentHeight: CGFloat = 0
    private var width: CGFloat { collectionView?.bounds.width ?? 0 }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        let items = itemsProvider()
        let count = collectionView.numberOfSections > 0 ? collectionView.numberOfItems(inSection: 0) : 0
        // データソースとの食い違いで落ちないよう、少ない方に合わせる
        let inputs = Array(items.prefix(count))
        placements = JournalPlacer.place(inputs, width: width, top: JournalLayout.headerHeight + 8)

        itemAttributes = placements.enumerated().map { index, p in
            let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            attrs.size = p.frame.size
            attrs.center = CGPoint(x: p.frame.midX, y: p.frame.midY)
            attrs.transform = CGAffineTransform(rotationAngle: p.angle)
            attrs.zIndex = index * 2
            return attrs
        }
        captionAttributes = placements.enumerated().map { index, p in
            let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: JournalLayout.captionKind,
                                                         with: IndexPath(item: index, section: 0))
            attrs.size = p.captionFrame.size
            attrs.center = CGPoint(x: p.captionFrame.midX, y: p.captionFrame.midY)
            attrs.transform = CGAffineTransform(rotationAngle: p.captionAngle)
            attrs.zIndex = index * 2 + 1
            return attrs
        }
        let header = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: JournalLayout.headerKind,
                                                      with: IndexPath(item: 0, section: 0))
        header.frame = CGRect(x: 0, y: 0, width: width, height: JournalLayout.headerHeight)
        headerAttributes = header

        if collectionView.numberOfSections > 1, collectionView.numberOfItems(inSection: 1) > 0 {
            let spot = JournalPlacer.nextSpot(after: placements, width: width, top: JournalLayout.headerHeight + 8)
            let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 1))
            attrs.size = spot.frame.size
            attrs.center = CGPoint(x: spot.frame.midX, y: spot.frame.midY)
            attrs.transform = CGAffineTransform(rotationAngle: spot.angle)
            attrs.zIndex = placements.count * 2 + 1
            spotAttributes = attrs
            contentHeight = spot.frame.maxY + JournalLayout.bottomClearance
        } else {
            spotAttributes = nil
            contentHeight = (placements.last?.bottom ?? JournalLayout.headerHeight) + JournalLayout.bottomClearance
        }
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: width, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var all = itemAttributes + captionAttributes
        if let header = headerAttributes { all.append(header) }
        if let spot = spotAttributes { all.append(spot) }
        return all.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section == 1 { return spotAttributes }
        return itemAttributes.indices.contains(indexPath.item) ? itemAttributes[indexPath.item] : nil
    }

    override func layoutAttributesForSupplementaryView(ofKind kind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch kind {
        case JournalLayout.headerKind: return headerAttributes
        case JournalLayout.captionKind:
            return captionAttributes.indices.contains(indexPath.item) ? captionAttributes[indexPath.item] : nil
        default: return nil
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        newBounds.width != collectionView?.bounds.width
    }
}
```

- [ ] **Step 4: 通ることを確認** — 単一 5 本、アプリ全体。
- [ ] **Step 5: コミット** — 件名「ノートのレイアウトを作る」

---

### Task 8: 写真・題名・見出し・「次はここ」のビュー

**Files:**
- Create: `PhotoKeyboardEx/Journal/PastedPhotoCell.swift`、`JournalCaptionView.swift`、`JournalHeaderView.swift`、`NextSpotCell.swift`
- Modify: `PhotoKeyboardFramework/LocalizeKey.swift`、ja / en `Localizable.strings`
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Consumes: `PrintShape` / `TapeStyle` / `JournalProp`（Task 5）、`TapeView` / `ClipView` / `TicketView` / `StarStickerView` / `TornEdge`（Task 6）、`Motion`（Task 4）
- Produces:
  - `PastedPhotoCell.reuseIdentifier`、`configure(image: UIImage?, placement: JournalPlacement, ticketText: String?, title: String)`、`photoViewForTesting: UIImageView`、`tapeViewsForTesting: [UIView]`
  - `JournalCaptionView.reuseIdentifier`、`configure(text: String)`、`label: UILabel`（3 行まで）
  - `JournalHeaderView.reuseIdentifier`、`configure(dateText: String)`
  - `NextSpotCell.reuseIdentifier`、`enum State { case next(remaining: Int), full }`、`configure(state:)`、`remainingLabel` / `titleLabel`
  - `LocalizeKey.journalNextSpot`（ja「次はここ」/ en "Next goes here"）、`journalRemaining`（ja「あと %d 枚」/ en "%d more to go"）、`journalFull`（ja「このノートはいっぱい」/ en "This notebook is full"）、`journalPhotoAccessibility`（ja「%@、写真」/ en "%@, photo"）、`journalAddPhotoAccessibility`（ja「写真を追加」/ en "Add photo"）

- [ ] **Step 1: 落ちるテストを書く**

```swift
    // MARK: - ノートの部品

    private func placement(_ shape: PrintShape, tape: TapeStyle = .black, prop: JournalProp = .none) -> JournalPlacement {
        JournalPlacement(frame: CGRect(x: 0, y: 0, width: 180, height: 200), angle: 0.05, shape: shape, tape: tape,
                         prop: prop, captionFrame: .zero, captionAngle: 0, captionSide: .below, bottom: 200, isLeft: true)
    }

    /// ポラロイドは白い縁があり、写真は縁の内側に入ること
    @MainActor
    func testPolaroidHasAWhiteBorder() {
        let cell = PastedPhotoCell(frame: CGRect(x: 0, y: 0, width: 180, height: 212))
        cell.configure(image: UIImage(), placement: placement(.polaroid), ticketText: nil, title: "ねむい")
        cell.layoutIfNeeded()
        let photo = cell.photoViewForTesting.frame
        XCTAssertGreaterThan(photo.minX, 0)
        XCTAssertGreaterThan(cell.bounds.maxY - photo.maxY, photo.minY, "下の余白が広くない")
    }

    /// テープの種類どおりに留めてあること(2 隅なら 2 枚、クリップなら クリップ)
    @MainActor
    func testTapeMatchesPlacement() {
        let cell = PastedPhotoCell(frame: CGRect(x: 0, y: 0, width: 180, height: 200))
        cell.configure(image: UIImage(), placement: placement(.print, tape: .corners), ticketText: nil, title: "")
        XCTAssertEqual(cell.tapeViewsForTesting.count, 2)
        cell.configure(image: UIImage(), placement: placement(.print, tape: .clip), ticketText: nil, title: "")
        XCTAssertTrue(cell.tapeViewsForTesting.first is ClipView)
        cell.configure(image: UIImage(), placement: placement(.print, tape: .black), ticketText: nil, title: "")
        XCTAssertEqual(cell.tapeViewsForTesting.count, 1)
    }

    /// VoiceOver で「題名、写真」と読めること
    @MainActor
    func testPhotoCellReadsItsTitle() {
        let cell = PastedPhotoCell(frame: CGRect(x: 0, y: 0, width: 180, height: 200))
        cell.configure(image: UIImage(), placement: placement(.print), ticketText: nil, title: "腹へった")
        XCTAssertTrue(cell.isAccessibilityElement)
        XCTAssertEqual(cell.accessibilityLabel, LocalizeKey.journalPhotoAccessibility.localizedString("腹へった"))
    }

    /// 題名は手書きの書体で 3 行まで
    @MainActor
    func testCaptionIsHandwrittenAndStopsAtThreeLines() {
        let caption = JournalCaptionView(frame: CGRect(x: 0, y: 0, width: 140, height: 64))
        caption.configure(text: String(repeating: "まーまーらいおん君による使い方の説明！", count: 4))
        XCTAssertEqual(caption.label.numberOfLines, 3)
        XCTAssertEqual(caption.label.font.fontName, UIFont.journal(.footnote).fontName)
    }

    /// 「次はここ」は残りの枚数を書き、いっぱいなら書き換わること。押せるボタンとして読めること
    @MainActor
    func testNextSpotShowsRemainingAndFull() {
        let cell = NextSpotCell(frame: CGRect(x: 0, y: 0, width: 170, height: 140))
        cell.configure(state: .next(remaining: 7))
        XCTAssertEqual(cell.titleLabel.text, LocalizeKey.journalNextSpot.localizedString())
        XCTAssertEqual(cell.remainingLabel.text, LocalizeKey.journalRemaining.localizedString(7))
        XCTAssertTrue(cell.accessibilityTraits.contains(.button))
        cell.configure(state: .full)
        XCTAssertEqual(cell.titleLabel.text, LocalizeKey.journalFull.localizedString())
        XCTAssertFalse(cell.accessibilityTraits.contains(.button), "いっぱいなのに押せる扱い")
    }
```

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー。

- [ ] **Step 3: 実装**

文言を `LocalizeKey`（`case journalNextSpot`、`journalRemaining`、`journalFull`、`journalPhotoAccessibility`、`journalAddPhotoAccessibility`）と ja / en に足す。`journalRemaining` と `journalPhotoAccessibility` は `localizedString(_ arguments:)` で差し込む（`%d` / `%@`）。

`PastedPhotoCell`:
```swift
//
//  PastedPhotoCell.swift
//  PhotoKeyboardEx
//
//  ノートに貼った写真 1 枚。形・テープ・小物は JournalPlacement に従う。
//  回転はレイアウトが持つので、ここでは回さない。
//

import UIKit
import PhotoKeyboardFramework

final class PastedPhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "PastedPhotoCell"
    static let polaroidSide: CGFloat = 7
    static let polaroidBottom: CGFloat = 26

    private let paperView = UIView()          // ポラロイドの縁。紙焼きのときは写真と同じ大きさ
    private let photoView = UIImageView()
    private var tapeViews: [UIView] = []
    private var propView: UIView?
    private var shape: PrintShape = .print
    private var tape: TapeStyle = .black
    private var prop: JournalProp = .none

    var photoViewForTesting: UIImageView { photoView }
    var tapeViewsForTesting: [UIView] { tapeViews }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        clipsToBounds = false
        paperView.backgroundColor = .bgSurface
        paperView.layer.shadowColor = UIColor.black.cgColor
        paperView.layer.shadowOpacity = 0.22
        paperView.layer.shadowRadius = 5
        paperView.layer.shadowOffset = CGSize(width: 0, height: 3)
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        contentView.addSubview(paperView)
        paperView.addSubview(photoView)
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
        tapeViews.forEach { $0.removeFromSuperview() }
        tapeViews = []
        propView?.removeFromSuperview()
        propView = nil
    }

    func configure(image: UIImage?, placement: JournalPlacement, ticketText: String?, title: String) {
        photoView.image = image
        shape = placement.shape
        tape = placement.tape
        prop = placement.prop
        accessibilityLabel = LocalizeKey.journalPhotoAccessibility.localizedString(title)

        tapeViews.forEach { $0.removeFromSuperview() }
        switch placement.tape {
        case .corners: tapeViews = [TapeView(style: .black), TapeView(style: .black)]
        case .clip: tapeViews = [ClipView()]
        default: tapeViews = [TapeView(style: placement.tape)]
        }
        tapeViews.forEach { contentView.addSubview($0) }

        propView?.removeFromSuperview()
        switch placement.prop {
        case .ticket:
            let ticket = TicketView()
            ticket.text = ticketText
            propView = ticket
        case .star: propView = StarStickerView()
        case .none: propView = nil
        }
        if let propView = propView { contentView.addSubview(propView) }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        paperView.frame = contentView.bounds
        switch shape {
        case .polaroid:
            photoView.frame = CGRect(x: Self.polaroidSide, y: Self.polaroidSide,
                                     width: bounds.width - Self.polaroidSide * 2,
                                     height: bounds.height - Self.polaroidSide - Self.polaroidBottom)
            paperView.layer.mask = nil
        case .torn:
            photoView.frame = paperView.bounds
            paperView.layer.mask = TornEdge.mask(for: paperView.bounds)
        case .print, .landscape:
            photoView.frame = paperView.bounds
            paperView.layer.mask = nil
        }
        paperView.layer.shadowPath = UIBezierPath(rect: paperView.bounds).cgPath

        switch tape {
        case .corners where tapeViews.count == 2:
            tapeViews[0].bounds = CGRect(x: 0, y: 0, width: 44, height: 16)
            tapeViews[0].center = CGPoint(x: bounds.maxX - 4, y: 10)
            tapeViews[0].transform = CGAffineTransform(rotationAngle: .pi / 4)
            tapeViews[1].bounds = tapeViews[0].bounds
            tapeViews[1].center = CGPoint(x: 4, y: bounds.maxY - 10)
            tapeViews[1].transform = CGAffineTransform(rotationAngle: .pi / 4)
        case .clip:
            tapeViews.first?.frame = CGRect(x: bounds.midX - 6, y: -16, width: 12, height: 34)
        default:
            let width: CGFloat = tape == .long ? 92 : 58
            tapeViews.first?.bounds = CGRect(x: 0, y: 0, width: width, height: 17)
            tapeViews.first?.center = CGPoint(x: bounds.midX, y: 0)
            tapeViews.first?.transform = CGAffineTransform(rotationAngle: -0.06)
        }

        switch prop {
        case .ticket: propView?.frame = CGRect(x: -10, y: -26, width: 88, height: 20)
        case .star: propView?.frame = CGRect(x: bounds.maxX - 14, y: bounds.maxY - 14, width: 22, height: 22)
        case .none: break
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            isHighlighted ? Motion.pressDown(self) : Motion.release(self)
        }
    }
}
```

`isHighlighted` の縮みは `Motion` がいまの `transform`（レイアウトが置いた回転）に掛け合わせるので、角度は保たれる。

`JournalCaptionView`（`UICollectionReusableView`）: `label` を bounds いっぱいに置き、`font = .journal(.footnote)`、`adjustsFontForContentSizeCategory = true`、`textColor = .textPrimary`、`numberOfLines = 3`、`lineBreakMode = .byTruncatingTail`。`isAccessibilityElement = false`（写真側が題名を読むので二重に読ませない）。

`JournalHeaderView`: `label` を左 24pt に、`font = .label(.caption2)`、`textColor = .pencil`、`configure(dateText:)` は `"\(dateText) — p.1"` を入れる。

`NextSpotCell`:
```swift
final class NextSpotCell: UICollectionViewCell {
    static let reuseIdentifier = "NextSpotCell"
    enum State: Equatable { case next(remaining: Int), full }

    let titleLabel = UILabel()
    let remainingLabel = UILabel()
    private let border = CAShapeLayer()
    private(set) var state: State = .next(remaining: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        border.fillColor = UIColor.clear.cgColor
        border.lineDashPattern = [5, 4]
        border.lineWidth = 1.5
        contentView.layer.addSublayer(border)
        [titleLabel, remainingLabel].forEach {
            $0.font = .journal(.subheadline)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = .pencil
            $0.textAlignment = .center
            $0.numberOfLines = 2
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        remainingLabel.font = .journal(.footnote)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -16),
            remainingLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            remainingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(state: State) {
        self.state = state
        switch state {
        case .next(let remaining):
            titleLabel.text = LocalizeKey.journalNextSpot.localizedString()
            remainingLabel.text = LocalizeKey.journalRemaining.localizedString(remaining)
            border.isHidden = false
            accessibilityLabel = LocalizeKey.journalAddPhotoAccessibility.localizedString()
            accessibilityTraits = .button
        case .full:
            titleLabel.text = LocalizeKey.journalFull.localizedString()
            remainingLabel.text = nil
            border.isHidden = true
            accessibilityLabel = titleLabel.text
            accessibilityTraits = .staticText
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.frame = contentView.bounds
        border.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 3).cgPath
        border.strokeColor = UIColor.pencil.resolvedColor(with: traitCollection).cgColor
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue, case .next = state else { return }
            isHighlighted ? Motion.pressDown(self) : Motion.release(self)
        }
    }
}
```

`journalAddPhotoAccessibility`（ja「写真を追加」/ en "Add photo"）もこのタスクで足す。Task 11 のシールも同じ文言を使う。

「次はここ」の枠の外（下）に「あと n 枚」を出すため、セル自身とレイアウトで `clipsToBounds = false`（既定）のままにする。

- [ ] **Step 4: 通ることを確認** — 単一 5 本、アプリ・Framework 全体（文言の漏れ）。
- [ ] **Step 5: コミット** — 件名「写真・題名・見出し・次はここ の部品を作る」

---

### Task 9: マイボードをノートに組み替える

**Files:**
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`（全体。`gridMetrics` / `createGridLayout` / `updateEmptyState` / 旧データソースを置き換え）
- Delete: `PhotoKeyboardEx/PhotoCollectionViewCell.swift`（pbxproj からも外す）
- Modify: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`（`// MARK: - 一覧のグリッド` の節と `renderedLineCount` / `makeLaidOutCell` を削除し、次のテストに置き換える）
- Modify: `PhotoKeyboardFramework/LocalizeKey.swift` と ja / en（`myBoardEmptyTitle` を削除。使う場所が無くなる）

**Interfaces:**
- Consumes: Task 5〜8 のすべて
- Produces: `ChildContentViewController` の公開面は変えない（`applyOnboarding(step:)`、`simulateOnboardingHintTapForTesting()`、`collectionView`）。追加で `func contextMenuActionsForTesting(at indexPath: IndexPath) -> [String]`（メニューの題名の列）

- [ ] **Step 1: 落ちるテストを書く**

```swift
    // MARK: - マイボード

    @MainActor
    private func makeBoard() -> ChildContentViewController? {
        let board = UIStoryboard(name: "ChildContent", bundle: nil).instantiateInitialViewController() as? ChildContentViewController
        board?.loadViewIfNeeded()
        board?.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = board
        window.isHidden = false
        board?.view.layoutIfNeeded()
        board?.collectionView.layoutIfNeeded()
        return board
    }

    /// マイボードはノートのレイアウトで、紙が敷いてあること
    @MainActor
    func testBoardIsANotebook() {
        guard let board = makeBoard() else { return XCTFail("マイボードを組み立てられない") }
        XCTAssertTrue(board.collectionView.collectionViewLayout is JournalLayout)
        XCTAssertTrue(board.collectionView.backgroundView is PaperBackgroundView)
        XCTAssertEqual(board.collectionView.numberOfSections, 2)
        XCTAssertEqual(board.collectionView.numberOfItems(inSection: 1), 1, "次はここ が無い")
    }

    /// 「次はここ」を押すと追加の導線に乗ること
    @MainActor
    func testTappingNextSpotRequestsAddPhoto() {
        guard let board = makeBoard() else { return XCTFail("マイボードを組み立てられない") }
        let asked = expectation(description: "追加の依頼")
        let token = NotificationCenter.default.addObserver(forName: .requestAddPhoto, object: nil, queue: .main) { _ in asked.fulfill() }
        defer { NotificationCenter.default.removeObserver(token) }
        board.collectionView(board.collectionView, didSelectItemAt: IndexPath(item: 0, section: 1))
        wait(for: [asked], timeout: 2)
    }

    /// 写真は長押しでコピーと削除のメニューを出すこと
    @MainActor
    func testPhotoLongPressOffersCopyAndDelete() {
        guard let board = makeBoard() else { return XCTFail("マイボードを組み立てられない") }
        guard board.collectionView.numberOfItems(inSection: 0) > 0 else {
            return XCTFail("写真が 1 枚も無い。見本の投入を確認する")
        }
        let titles = board.contextMenuActionsForTesting(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(titles, [LocalizeKey.menuCopy.localizedString(), LocalizeKey.menuDelete.localizedString()])
    }

    /// VoiceOver でもコピーと削除ができること
    @MainActor
    func testPhotoOffersAccessibilityActions() {
        guard let board = makeBoard(), board.collectionView.numberOfItems(inSection: 0) > 0 else { return }
        let cell = board.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(cell?.accessibilityCustomActions?.count, 2)
    }
```

既存の `testTappingEmptySlot...` 系や `gridMetrics` 系は master に無いので、削除対象は `// MARK: - 一覧のグリッド` の節（`testGridMetrics*`、`testTitleAllowsTwoLines`、`testInfoHeightFitsTitleLines`、`testLongTitleRendersOnTwoLines`、`testShortTitleStaysOnOneLine`、`testVeryLongTitleStopsAtTwoLines`）とヘルパー `renderedLineCount`、`makeLaidOutCell`。

- [ ] **Step 2: 落ちることを確認** — `testBoardIsANotebook` が FAIL（まだ格子レイアウト）。

- [ ] **Step 3: 組み替える**

`ChildContentViewController`:
- `import` は現状のまま
- `commonInit()`: `collectionView.collectionViewLayout = journalLayout`（`private let journalLayout = JournalLayout()`、`itemsProvider` に `journalInputs()` を渡す）、`collectionView.backgroundView = PaperBackgroundView()`、`collectionView.backgroundColor = .bgBase`、`PastedPhotoCell` / `NextSpotCell` / `JournalCaptionView`（`captionKind`）/ `JournalHeaderView`（`headerKind`）を register。`PhotoCollectionViewCell` の register を消す
- `journalInputs()`:
```swift
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private static let ticketFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    private func journalInputs() -> [JournalItemInput] {
        (realmPhotos.map { Array($0) } ?? []).map { photo in
            let ratio = photo.imageHeight > 0 ? CGFloat(photo.imageWidth) / CGFloat(photo.imageHeight) : 1
            return JournalItemInput(id: photo.id, aspectRatio: ratio,
                                    dayKey: Self.dayFormatter.string(from: photo.pastedAt))
        }
    }
```
- `numberOfSections` = 2。セクション 0 は `realmPhotos?.count ?? 0`、セクション 1 は 1
- `cellForItemAt`: セクション 0 は `PastedPhotoCell.configure(image: photo.thumbnail(maxPixelSize: 900) ?? photo.image, placement: journalLayout.placements[item], ticketText: prop が .ticket なら ticketFormatter で pastedAt, title: photo.text)` と `accessibilityCustomActions`（コピー / 削除。既存の `copyToPasteboard(photo:)` と `confirmDelete(id:)` を呼ぶ）。`journalLayout.placements` が足りない場合（レイアウトより先に呼ばれた）は `collectionView.collectionViewLayout.prepare()` を呼んでから読む。セクション 1 は `NextSpotCell.configure(state: count >= RealmManager.photoLimit ? .full : .next(remaining: RealmManager.photoLimit - count))`
  - `RealmPhoto.thumbnail(maxPixelSize:)` が無ければ `photo.image` をそのまま使う（`grep -n "func thumbnail" PhotoKeyboardFramework/Photo.swift` で確認）
- `viewForSupplementaryElementOfKind`: `captionKind` は `JournalCaptionView.configure(text: photo.text)`、`headerKind` は `JournalHeaderView.configure(dateText:)` に先頭の写真の `pastedAt`（写真が無ければ今日）を `ticketFormatter` で
- `didSelectItemAt`: セクション 0 は `showPhotoDetail`、セクション 1 は、いっぱいでなければ `.requestAddPhoto` を投げる
- 長押し: `collectionView(_:contextMenuConfigurationForItemsAt:point:)`（iOS 16）でセクション 0 の 1 件に `makeMenu(for:)` を返す。`makeMenu` は今の実装（コピー / 削除）を流用。`contextMenuActionsForTesting(at:)` は `makeMenu(for:)` の `children.map(\.title)` を返す
- `updateEmptyState()` と空状態の文言は削除（「次はここ」が空状態を兼ねる）。`LocalizeKey.myBoardEmptyTitle` と ja / en の行も削除
- `gridMetrics`、`createGridLayout`、`gridSpacing`、`gridColumns`、`cellInfoHeight` を削除
- `reloadData` の前に `journalLayout.invalidateLayout()` を呼ぶ（写真の列が変わったとき）
- `PhotoCollectionViewCell.swift` を削除し、pbxproj から外す:
```ruby
require 'xcodeproj'
project = Xcodeproj::Project.open('PhotoKeyboardEx.xcodeproj')
project.files.select { |f| f.path == 'PhotoCollectionViewCell.swift' && f.real_path.to_s.include?('/PhotoKeyboardEx/PhotoCollectionViewCell.swift') }.each(&:remove_from_project)
project.save
```
（キーボード拡張にも同名の `PhotoCollectionViewCell.swift` がある。**拡張側は消さない**。`real_path` で区別する）

- [ ] **Step 4: 通ることを確認** — 単一 4 本、アプリ・Framework 全体。`grep -rn "gridMetrics\|PhotoCollectionViewCell" PhotoKeyboardEx PhotoKeyboardExTests` がアプリとテストで 0 件（拡張は除く）。
- [ ] **Step 5: シミュレータで目視** — 次のコマンドで入れて、起動直後の Top を越えるために App Group の `registerNeedFlag` を false にしてからマイボードを撮る。
```bash
xcodebuild -project PhotoKeyboardEx.xcodeproj -scheme PhotoKeyboardEx -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build/sim-dd build 2>&1 | tail -1
xcrun simctl boot "iPhone 17" 2>/dev/null; xcrun simctl install booted build/sim-dd/Build/Products/Debug-iphonesimulator/PhotoKeyboardEx.app
xcrun simctl spawn booted defaults write group.bocchi.PhotoKeyboardEx registerNeedFlag -bool false
xcrun simctl launch --terminate-running-process booted bocchi.PhotoKeyboardEx; sleep 4
xcrun simctl io booted screenshot build/journal-board.png
```
`build/journal-board.png` を Read で開き、方眼の紙に見本の写真が斜めに貼ってあり、題名が手書きで、下に「次はここ」があることを確認して報告に書く。
- [ ] **Step 6: コミット** — 件名「マイボードをノートに組み替える」

---

### Task 10: 案内行・保存の知らせ・Realm 通知を持ち込む

**Files:**
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`
- Modify: `PhotoKeyboardEx/AddViewController.swift`（`.finishUpload` を `dismiss` の完了後へ）
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Produces: `ChildContentViewController.viewDidLayoutSubviews()` の inset 調整、`realmObjectDidChange()` の作り直し省略、`knownPhotoIds: Set<String>`（private）

- [ ] **Step 1: 落ちるテストを書く**

```swift
    /// 案内行が出ている間、ノートの見出しは案内行の下に来ること
    @MainActor
    func testNotebookStartsBelowTheHint() {
        guard let board = makeBoard() else { return XCTFail("マイボードを組み立てられない") }
        board.applyOnboarding(step: .savePhoto)
        board.view.layoutIfNeeded()
        let header = board.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(
            ofKind: JournalLayout.headerKind, at: IndexPath(item: 0, section: 0))!
        let top = board.collectionView.convert(header.frame, to: board.view).minY
        let hint = board.view.subviews.first { $0 is OnboardingHintView }!
        XCTAssertGreaterThanOrEqual(top, hint.frame.maxY - 1)
    }

    /// 案内行が消えたら押し下げも戻ること
    @MainActor
    func testInsetReturnsWhenHintHides() {
        guard let board = makeBoard() else { return XCTFail("マイボードを組み立てられない") }
        board.applyOnboarding(step: .savePhoto)
        board.view.layoutIfNeeded()
        XCTAssertGreaterThan(board.collectionView.contentInset.top, 0)
        board.applyOnboarding(step: .done)
        board.view.layoutIfNeeded()
        XCTAssertEqual(board.collectionView.contentInset.top, 0, accuracy: 0.5)
    }

    /// 下へスクロールしている間に案内行が消えても、見ている位置は動かないこと
    @MainActor
    func testHidingHintDoesNotMoveScrolledNotebook() {
        guard let board = makeBoard() else { return XCTFail("マイボードを組み立てられない") }
        board.view.frame.size.height = 400
        board.applyOnboarding(step: .savePhoto)
        board.view.layoutIfNeeded()
        board.collectionView.contentOffset.y = 120
        board.applyOnboarding(step: .done)
        board.view.layoutIfNeeded()
        XCTAssertEqual(board.collectionView.contentOffset.y, 120, accuracy: 0.5)
    }

    /// 並びが変わっていない Realm 通知では作り直さないこと(貼る動きを途中で消さない)
    @MainActor
    func testUnchangedRealmChangeDoesNotReloadNotebook() {
        guard let board = makeBoard() else { return XCTFail("マイボードを組み立てられない") }
        final class Counter: NSObject, UICollectionViewDataSource {
            let base: UICollectionViewDataSource; var cells = 0
            init(base: UICollectionViewDataSource) { self.base = base }
            func numberOfSections(in cv: UICollectionView) -> Int { base.numberOfSections?(in: cv) ?? 1 }
            func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { base.collectionView(cv, numberOfItemsInSection: s) }
            func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell { cells += 1; return base.collectionView(cv, cellForItemAt: ip) }
            func collectionView(_ cv: UICollectionView, viewForSupplementaryElementOfKind k: String, at ip: IndexPath) -> UICollectionReusableView {
                base.collectionView!(cv, viewForSupplementaryElementOfKind: k, at: ip)
            }
        }
        board.beginAppearanceTransition(true, animated: false)
        board.endAppearanceTransition()
        let spy = Counter(base: board)
        board.collectionView.dataSource = spy
        board.collectionView.reloadData()
        board.collectionView.layoutIfNeeded()
        let before = spy.cells
        board.realmObjectDidChange()
        let settled = expectation(description: "main.async")
        DispatchQueue.main.async { settled.fulfill() }
        wait(for: [settled], timeout: 2)
        board.collectionView.layoutIfNeeded()
        XCTAssertEqual(spy.cells, before, "並びが同じなのにノートを作り直している")
    }
```

- [ ] **Step 2: 落ちることを確認** — `testNotebookStartsBelowTheHint` と `testInsetReturnsWhenHintHides` が FAIL。

- [ ] **Step 3: 持ち込む**

`feature/clay-game-ui` の `ChildContentViewController` から、次の部分を**書き写す**（`git show feature/clay-game-ui:PhotoKeyboardEx/ChildContentViewController.swift` で参照）。`slots` / `BoardSlots` に依存する行は `realmPhotos?.count` に置き換える。

```swift
    /// 直前に並べていた写真の id。増えた写真を見つけ、並びが同じ通知を見分けるために持つ
    private var knownPhotoIds: Set<String> = []

    private func currentPhotoIds() -> [String] {
        (realmPhotos.map { Array($0) } ?? []).map { $0.id }
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
```
`applyOnboarding(step:)` の末尾に `view.setNeedsLayout()`（案内行の出入りは `isHidden` だけで親のレイアウトが起きないため）。`viewWillAppear` の `reloadData()` の後に `knownPhotoIds = Set(currentPhotoIds())`。`realmObjectDidChange`:
```swift
    func realmObjectDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let ids = self.currentPhotoIds()
            // 貼る動きの途中で Realm の通知で作り直さない。並びが変わっていなければ何もしない
            if Set(ids) == self.knownPhotoIds && ids.count == self.collectionView.numberOfItems(inSection: 0) {
                return
            }
            self.journalLayout.invalidateLayout()
            self.collectionView?.reloadData()
            self.knownPhotoIds = Set(ids)
        }
    }
```
`realmObjectDidChange` が private なら internal にする。`reloadSaveState`（削除）は作り直して `knownPhotoIds` を更新する。

`AddViewController` の保存成功の経路で、`.finishUpload` の post を `dismiss(animated: true) { NotificationCenter.default.post(name: .finishUpload, object: nil, userInfo: nil) }` に移す（日本語コメント「シートが下りてから知らせる。閉じている最中に貼る動きが走ると、その下で見えないまま終わる」）。

- [ ] **Step 4: 通ることを確認** — 単一 4 本、アプリ全体。
- [ ] **Step 5: コミット** — 件名「案内行の押し下げと、保存・Realm 通知の順番を持ち込む」

---

### Task 11: 付箋・丸いシール・ロゴ

**Files:**
- Modify: `PhotoKeyboardEx/Onboarding/OnboardingHintView.swift`
- Create: `PhotoKeyboardEx/Journal/StickerButton.swift`
- Modify: `PhotoKeyboardEx/MainTabViewController.swift`（`fabButton` と `layoutFAB()`、`applyBrandTitle()`）
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`（案内行の制約）
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Consumes: `Motion`、`Haptic`、`UIFont.journal` / `label`
- Produces: `StickerButton: UIControl`（`init(symbol: String, diameter: CGFloat = 64)`、`restingAngle: CGFloat = -6°`）、`MainTabViewController.fabButton: StickerButton`、`MainTabViewController.brandTitleViewForTesting: UIView?`

- [ ] **Step 1: 落ちるテストを書く**

```swift
    // MARK: - 付箋とシール

    /// 案内行は付箋。付箋の色で、手書きの書体、少し傾いている
    @MainActor
    func testHintIsAStickyNote() {
        let hint = OnboardingHintView()
        hint.apply(step: .savePhoto)
        XCTAssertEqual(hint.backgroundColor, .accentSoft)
        XCTAssertNotEqual(hint.transform, .identity, "傾いていない")
        XCTAssertEqual(hint.textLabelForTesting.font.fontName, UIFont.journal(.subheadline).fontName)
    }

    /// 追加ボタンは付箋の色の丸いシールで、64pt、傾いていて、押すと沈み振動すること
    @MainActor
    func testStickerButtonIsATiltedRoundSticker() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        final class Rec: HapticDriver { var played: [Haptic.Kind] = []; func play(_ k: Haptic.Kind) { played.append(k) } }
        let rec = Rec(); let prev = Haptic.driver; Haptic.driver = rec; defer { Haptic.driver = prev }
        let sticker = StickerButton(symbol: Symbol.add)
        sticker.layoutIfNeeded()
        XCTAssertEqual(sticker.bounds.width, 64)
        XCTAssertEqual(atan2(sticker.transform.b, sticker.transform.a), -6 * .pi / 180, accuracy: 0.001)
        sticker.isHighlighted = true
        XCTAssertLessThan(hypot(sticker.transform.a, sticker.transform.b), 1)
        XCTAssertEqual(rec.played, [.tap])
        sticker.isHighlighted = false
        XCTAssertEqual(atan2(sticker.transform.b, sticker.transform.a), -6 * .pi / 180, accuracy: 0.001, "離したら傾きが消えた")
    }

    /// ロゴはラベルライターのテープで、タイプライターの書体。読み上げはマイボード
    @MainActor
    func testLogoIsALabelTape() {
        let tab = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabViewController") as? MainTabViewController
        tab?.loadViewIfNeeded()
        let label = tab?.brandTitleViewForTesting?.subviews.compactMap { $0 as? UILabel }.first
        XCTAssertEqual(label?.font.fontName, UIFont.label(.headline).fontName)
        XCTAssertEqual(tab?.brandTitleViewForTesting?.accessibilityLabel, LocalizeKey.navMyBoard.localizedString())
    }
```
（`Main.storyboard` の `MainTabViewController` に Storyboard ID が無ければ、`testLogoIsALabelTape` の組み立てを `instantiateInitialViewController()` から辿る形に書き換え、辿り方を報告に書く。Storyboard ID を足すのは可）

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー（`StickerButton`、`textLabelForTesting`、`brandTitleViewForTesting` が無い）。

- [ ] **Step 3: 実装**

`OnboardingHintView`:
- `backgroundColor = .accentSoft`、`applyCornerRadius` をやめ `layer.cornerRadius = 2`
- `label.font = .journal(.subheadline)`、`adjustsFontForContentSizeCategory = true`
- 影: `layer.shadowColor = UIColor.black.cgColor`、`shadowOpacity 0.14`、`shadowRadius 5`、`shadowOffset (0, 5)`（`clipsToBounds = false`）
- 右下の折り返し: 16pt の三角の `CAShapeLayer`（`UIColor.black.withAlphaComponent(0.12)`）を `layoutSubviews` で右下に置く
- `transform = CGAffineTransform(rotationAngle: -1.2 * .pi / 180)`
- `var textLabelForTesting: UILabel { label }`
- シェブロンは `tintColor = .textPrimary`

`ChildContentViewController.setupOnboardingHint()`: 左右を `Spacing.l`（16）+ 2 にし、trailing を `lessThanOrEqualTo` にして付箋が中身の幅に縮むようにする（`label` の最大幅は画面幅の 80%: `onboardingHint.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)`）。

`StickerButton`:
```swift
//
//  StickerButton.swift
//  PhotoKeyboardEx
//
//  付箋を丸く切ったシールの追加ボタン。少し傾け、内側に点線の円。
//

import UIKit
import PhotoKeyboardFramework

final class StickerButton: UIControl {
    let diameter: CGFloat
    let restingAngle: CGFloat = -6 * .pi / 180
    private let imageView = UIImageView()
    private let ring = CAShapeLayer()

    init(symbol: String, diameter: CGFloat = 64) {
        self.diameter = diameter
        super.init(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        backgroundColor = .accentSoft
        layer.cornerRadius = diameter / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 8)
        ring.fillColor = UIColor.clear.cgColor
        ring.lineDashPattern = [3, 3]
        ring.lineWidth = 1
        layer.addSublayer(ring)
        imageView.image = .symbol(symbol, pointSize: diameter * 0.42, weight: .regular)
        imageView.tintColor = .textPrimary
        imageView.contentMode = .center
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: diameter),
                                     heightAnchor.constraint(equalToConstant: diameter)])
        transform = CGAffineTransform(rotationAngle: restingAngle)
        accessibilityTraits = .button
        accessibilityLabel = LocalizeKey.journalAddPhotoAccessibility.localizedString()
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        ring.frame = bounds
        ring.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 4, dy: 4)).cgPath
        ring.strokeColor = UIColor.textPrimary.withAlphaComponent(0.25).resolvedColor(with: traitCollection).cgColor
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            if isHighlighted {
                Haptic.play(.tap)
                Motion.pressDown(self)
            } else {
                Motion.release(self)
            }
        }
    }
}
```

`MainTabViewController`:
- `var fabButton = StickerButton(symbol: Symbol.add)`。`layoutFAB()` は影や角丸の直書きを消し、`addTarget(self, action: #selector(tapFAB), for: .touchUpInside)`、`view.addSubview`、trailing / bottom を `-Spacing.l - 2` / `-Spacing.l - 6` にするだけ
- `applyBrandTitle()` を差し替え: 白い帯（`backgroundColor = .onAccent`）に黒字（`.accent`）の `UILabel`（`font = .label(.headline)`、`text = "periperi"`、左右 8pt / 上下 2pt）を載せた `UIView` を `navigationItem.titleView` に。帯の下に 1pt の影（`layer.shadowOffset (0,1)`、`shadowOpacity 0.25`、`shadowRadius 0`）。`accessibilityLabel = navMyBoard`、`.header`。`brandTitleViewForTesting` は `navigationItem.titleView` を返す。ロゴ画像 `periperi_wordmark` を使う経路と `applyFallbackBrandTitle` は削除

- [ ] **Step 4: 通ることを確認** — 単一 3 本、アプリ全体（既存の `testOnboardingHint*` が文言と表示/非表示だけを見ていることを確認）。
- [ ] **Step 5: シミュレータで目視** — Task 9 Step 5 と同じ手順で撮り、付箋・シール・ロゴを確認。
- [ ] **Step 6: コミット** — 件名「案内行を付箋に、追加ボタンを丸いシールに、ロゴをラベルにする」

---

### Task 12: 貼る動きと「いっぱい」の演出

**Files:**
- Modify: `PhotoKeyboardFramework/DefaultsKeys.swift`（`hasCelebratedNotebookFull`）
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`（`reloadAfterPost` で貼る動き）
- Modify: `PhotoKeyboardEx/Journal/NextSpotCell.swift`（書かれるように現れる）
- Test: 両テストファイル

**Interfaces:**
- Consumes: `Motion.paste`、`Haptic.play(.paste / .full)`
- Produces: `GroupeDefaults.hasCelebratedNotebookFull() -> Bool`、`markNotebookFullCelebrated()`、`NextSpotCell.revealWriting(completion:)`、`static func newlyPastedIds(previous: Set<String>, current: [String]) -> [String]`（`ChildContentViewController` の static、純粋）

- [ ] **Step 1: 落ちるテストを書く**

Framework（`testOnboardingFlagsAreOnBeforeFirstRunAndOffAfterDone` の直後）:
```swift
    /// ノートがいっぱいになった演出は一度きりで、記録が残ること
    func testNotebookFullCelebrationIsRemembered() {
        let defaults = GroupeDefaults.shared
        defaults.sharedDefaults.removeObject(forKey: "hasCelebratedNotebookFull")
        XCTAssertFalse(defaults.hasCelebratedNotebookFull())
        defaults.markNotebookFullCelebrated()
        XCTAssertTrue(defaults.hasCelebratedNotebookFull())
        defaults.sharedDefaults.removeObject(forKey: "hasCelebratedNotebookFull")
    }
```
アプリ:
```swift
    /// 直前に無かった写真だけを「貼った」とみなすこと。並び替えや削除では動かさない
    func testNewlyPastedIdsFindsOnlyUnknownIds() {
        XCTAssertEqual(ChildContentViewController.newlyPastedIds(previous: ["a", "b"], current: ["a", "b", "c"]), ["c"])
        XCTAssertEqual(ChildContentViewController.newlyPastedIds(previous: ["a", "b"], current: ["b", "a"]), [])
        XCTAssertEqual(ChildContentViewController.newlyPastedIds(previous: ["a", "b"], current: ["a"]), [])
    }

    /// 「いっぱい」は左から書かれるように現れ、終わると全部見えていること
    @MainActor
    func testFullNoteRevealsLikeHandwriting() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        let cell = NextSpotCell(frame: CGRect(x: 0, y: 0, width: 170, height: 140))
        cell.configure(state: .full)
        let done = expectation(description: "書き終わり")
        cell.revealWriting { done.fulfill() }
        wait(for: [done], timeout: 3)
        XCTAssertNil(cell.titleLabel.layer.mask, "書き終わっても隠れている")
    }
```

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー。

- [ ] **Step 3: 実装**

`DefaultsKeys`: `Keys` に `hasCelebratedNotebookFull`、`markOnboardingCelebrated()` の直後に 2 関数（既存の `hasCelebratedOnboarding` と同じ形）。

`ChildContentViewController`:
```swift
    static func newlyPastedIds(previous: Set<String>, current: [String]) -> [String] {
        current.filter { !previous.contains($0) }
    }

    @objc func reloadAfterPost(notification: Notification) {
        journalLayout.invalidateLayout()
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        let ids = currentPhotoIds()
        let pasted = Self.newlyPastedIds(previous: knownPhotoIds, current: ids)
        knownPhotoIds = Set(ids)
        guard let newId = pasted.last, let index = ids.firstIndex(of: newId) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        // 貼った写真まで下げてから、上から落としてくる
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        collectionView.layoutIfNeeded()
        if let cell = collectionView.cellForItem(at: indexPath),
           let final = collectionView.layoutAttributesForItem(at: indexPath)?.transform {
            Haptic.play(.paste)
            Motion.paste(cell, to: final) { [weak self] in self?.celebrateIfFull() }
        } else {
            celebrateIfFull()
        }
    }

    private func celebrateIfFull() {
        guard currentPhotoIds().count >= RealmManager.photoLimit,
              !GroupeDefaults.shared.hasCelebratedNotebookFull(),
              let spot = collectionView.cellForItem(at: IndexPath(item: 0, section: 1)) as? NextSpotCell else { return }
        GroupeDefaults.shared.markNotebookFullCelebrated()
        spot.revealWriting { Haptic.play(.full) }
    }
```

`NextSpotCell.revealWriting(completion:)`:
```swift
    /// 「いっぱい」を鉛筆で書くように左から見せる。視差効果を減らす設定ならフェードだけ
    func revealWriting(completion: @escaping () -> Void) {
        if Motion.isReduced {
            titleLabel.alpha = 0
            UIView.animate(withDuration: 0.3, animations: { self.titleLabel.alpha = 1 }) { _ in completion() }
            return
        }
        let mask = CALayer()
        mask.backgroundColor = UIColor.black.cgColor
        mask.frame = CGRect(x: 0, y: 0, width: 0, height: titleLabel.bounds.height)
        titleLabel.layer.mask = mask
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.titleLabel.layer.mask = nil
            completion()
        }
        let grow = CABasicAnimation(keyPath: "bounds.size.width")
        grow.fromValue = 0
        grow.toValue = titleLabel.bounds.width
        grow.duration = 0.8
        mask.anchorPoint = CGPoint(x: 0, y: 0)
        mask.position = .zero
        mask.bounds = CGRect(x: 0, y: 0, width: titleLabel.bounds.width, height: titleLabel.bounds.height)
        mask.add(grow, forKey: "write")
        CATransaction.commit()
    }
```

- [ ] **Step 4: 通ることを確認** — 単一 3 本、両方の全テスト。
- [ ] **Step 5: コミット** — 件名「写真を貼る動きと、ノートがいっぱいになる演出を足す」

---

### Task 13: 実機確認

controller が行う（実装エージェントは使わない）。

- [ ] **Step 1:** 実機（`00008140-001544A83E13801C`）へ上書きインストール。上書きなので写真は消えない。インストール後に共有領域のバックアップを取る（`xcrun devicectl device copy from --domain-type appGroupDataContainer ... --source Library/Preferences/group.bocchi.PhotoKeyboardEx.plist` と Realm 本体）
- [ ] **Step 2:** 利用者に見てもらう — ライト・ダーク、写真の散らばり方、題名の手書き、「次はここ」、付箋、シール、写真を 1 枚貼ったときの動き、長押しメニュー
- [ ] **Step 3:** 戻りがあれば `JournalPlacer` の定数（大きさ・角度・重なり）と色の値だけで調整し、テストを通して 1 コミット
- [ ] **Step 4:** ブランチ全体の最終レビューのあと、`git push -u origin feature/journal-notebook` と PR 作成
