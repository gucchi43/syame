# クレイ配色 B・番号スロット・浮く FAB 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 実機で「地味・安っぽい」と判断された配色を、モックで選んだ B（トイ・クレイ）に差し替え、進み具合のピルを廃止して空きスロットに番号を入れ、FAB をもっと大きく浮かせる。

**Architecture:** 部品の構造（`ClaySurface` / `ClayButton` / `BoardSlots`）は変えない。変えるのはトークン値、`ClaySurface` の影とハイライトの強さと「底の厚み」、空きスロットの色の循環と番号、`BoardProgressView` の削除、FAB の寸法。

**Tech Stack:** Swift 5 / UIKit / XCTest。`xcodebuild test`（iPhone 17 シミュレータ）。

**Spec:** `docs/superpowers/specs/2026-09-24-clay-game-ui-design.md` に加え、利用者が選んだモック 2 つ（配色 B: https://claude.ai/artifact/J39MaVv1AmkBntWF7ZgbMX 、進み具合と FAB: https://claude.ai/artifact/FsxzgpoFvVLLE1x2eBZ4PD の案 1）。矛盾する場合はモックの決定が spec に優先する（ピルは廃止、FAB は 56pt より大きく）。

## Global Constraints

- 前計画 `2026-09-25-clay-game-ui-foundation.md` の Global Constraints をすべて引き継ぐ（日本語コメント、絵文字なし、作成者 gucchi43、末尾 2 行、ブランチ `feature/clay-game-ui`、master へ直接 push しない、`layer.shadow*` は `Clay.swift` だけ、拡張は触らない、新しい文言は ja/en 両方）
- 空きスロットの色は **5 色を添字で循環**させる。隣り合うマスが同じ色にならないこと（2 列・3 列）
- 空きスロットの「+」と番号は、5 色すべての面に対して **3:1 以上**
- `textPrimary` は `bgBase` / `bgSurface` / 5 色すべてに対して 4.5:1 以上（既存テスト `testTextColorsMeetContrastRequirement` と Task 1 で追加する検証）
- 進み具合のピル（`BoardProgressView`、`boardProgress` / `boardComplete` の文言）は**削除**する。コンプリートの演出（波と振動）は残す
- FAB は **72pt 以上**
- 各タスクのコミットは `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` と `Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc` を末尾に付ける

---

## ファイル構成

| 操作 | パス | 役割 |
|---|---|---|
| 変更 | `PhotoKeyboardFramework/DesignSystem.swift` | `bgBase` / `bgSurface` / `accentSoft` を B の値に |
| 変更 | `PhotoKeyboardFramework/Clay.swift` | スロット 5 色 + `claySlotColor(at:)`、`claySlotInk`、`clayOrange` / `onClayOrange`、影とハイライトの強化、`ClaySurface.baseDepth`、`ClayButton` の既定色 |
| 変更 | `PhotoKeyboardEx/Board/EmptySlotCell.swift` | `configure(index:)`、番号ラベル、色の循環 |
| 削除 | `PhotoKeyboardEx/Board/BoardProgressView.swift` | ピル |
| 変更 | `PhotoKeyboardEx/ChildContentViewController.swift` | ヘッダ削除、空きスロットへ添字を渡す |
| 変更 | `PhotoKeyboardEx/MainTabViewController.swift` | FAB 76pt、底の厚み |
| 変更 | `PhotoKeyboardFramework/LocalizeKey.swift`、ja/en `Localizable.strings` | `boardProgress` / `boardComplete` 削除 |
| 変更 | `PhotoKeyboardEx.xcodeproj/project.pbxproj` | `BoardProgressView.swift` の登録解除 |
| 変更 | 両テストファイル | 追加・削除・書き換え |

---

### Task 1: 配色 B のトークンと、面の膨らみの強化

**Files:**
- Modify: `PhotoKeyboardFramework/DesignSystem.swift:76,80,100`
- Modify: `PhotoKeyboardFramework/Clay.swift`（面色の節、`ClaySurface.applyColors`、`ClayButton.commonInit`）
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Produces:
  - `UIColor.claySlotPalette: [UIColor]`（5 色、順に 空 / 桃 / ミント / ピンク / レモン）
  - `UIColor.claySlotColor(at index: Int) -> UIColor`（`index % 5`）
  - `UIColor.claySlotInk: UIColor`（空きスロットの「+」と番号。5 色すべてに 3:1 以上）
  - `UIColor.clayOrange` / `UIColor.onClayOrange`（ボタンの既定色と文字色）
  - `ClaySurface.baseDepth: CGFloat`（既定 0。0 より大きいと、面の下に厚みの層を描く）

- [ ] **Step 1: 落ちるテストを書く**

`testTextOnClaySurfacesStaysReadable` の直後に足す。

```swift
    /// 空きスロットの 5 色は、2 列でも 3 列でも隣り合うマスが同じ色にならないこと。
    /// 横隣りは +1、縦隣りは列数ぶん先。5 は 2 でも 3 でも割り切れないので重ならない
    func testSlotPaletteNeverRepeatsOnNeighbors() {
        XCTAssertEqual(UIColor.claySlotPalette.count, 5)
        for columns in [2, 3] {
            for index in 0..<24 {
                let here = UIColor.claySlotColor(at: index)
                XCTAssertFalse(here === UIColor.claySlotColor(at: index + 1), "\(columns)列: \(index) の横隣りが同じ色")
                XCTAssertFalse(here === UIColor.claySlotColor(at: index + columns), "\(columns)列: \(index) の縦隣りが同じ色")
            }
        }
        XCTAssertTrue(UIColor.claySlotColor(at: 0) === UIColor.claySlotColor(at: 5), "5 で循環していない")
    }

    /// 空きスロットの「+」と番号は、どの面色の上でも 3:1 以上(WCAG 1.4.11)。
    /// 前の実装は 1.33:1 で、押せる場所に見えなかった
    func testSlotInkIsVisibleOnEverySlotColor() {
        for dark in [false, true] {
            for (i, base) in UIColor.claySlotPalette.enumerated() {
                XCTAssertGreaterThanOrEqual(contrastRatio(.claySlotInk, base, dark: dark), 3.0,
                                            "\(dark ? "ダーク" : "ライト") スロット\(i): + が面に沈む")
            }
        }
    }

    /// 本文は新しい地・面・スロット色すべての上で読めること
    func testTextStaysReadableOnPaletteB() {
        for dark in [false, true] {
            for base in [UIColor.bgBase, .bgSurface, .clayOrange] + UIColor.claySlotPalette {
                XCTAssertGreaterThanOrEqual(contrastRatio(.textPrimary, base, dark: dark), 4.5,
                                            "\(dark ? "ダーク" : "ライト"): 本文が読めない面がある")
            }
            XCTAssertGreaterThanOrEqual(contrastRatio(.onClayOrange, .clayOrange, dark: dark), 4.5,
                                        "\(dark ? "ダーク" : "ライト"): オレンジのボタンの文字が読めない")
        }
    }

    /// 底の厚みを付けると、面の下に厚みの層が描かれること
    @MainActor
    func testSurfaceDrawsBaseDepthBelowBody() {
        let surface = ClaySurface(style: .raised)
        surface.frame = CGRect(x: 0, y: 0, width: 120, height: 60)
        surface.baseDepth = 8
        surface.layoutIfNeeded()
        let band = bandLuminance(of: surface, dark: false)
        XCTAssertGreaterThan(band.top, band.bottom + 2, "厚みを付けても上端が明るいこと")
        // 下端の外側 8pt に、面より暗い帯がある
        let below = bottomBandLuminance(of: surface, depth: 8, dark: false)
        XCTAssertLessThan(below, band.top - 10, "厚みの層が描かれていない")
    }

    /// 面の下端の外側(厚みの層が来る位置)の輝度。bandLuminance と同じ描き方で、frame の下へ depth ぶん広げて描く
    @MainActor
    private func bottomBandLuminance(of view: UIView, depth: CGFloat, dark: Bool) -> Double {
        view.overrideUserInterfaceStyle = dark ? .dark : .light
        let size = CGSize(width: view.bounds.width, height: view.bounds.height + depth)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.magenta.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            view.layer.render(in: context.cgContext)
        }
        guard let cg = image.cgImage else { return 0 }
        let w = cg.width, h = cg.height
        var px = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var sum = 0.0, n = 0.0
        for y in (h - Int(depth) + 1)..<(h - 1) {
            for x in Int(Double(w) * 0.3)..<Int(Double(w) * 0.7) {
                let i = (y * w + x) * 4
                sum += 0.2126 * Double(px[i]) + 0.7152 * Double(px[i + 1]) + 0.0722 * Double(px[i + 2])
                n += 1
            }
        }
        return sum / max(n, 1)
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: 単一テスト `testSlotPaletteNeverRepeatsOnNeighbors`
Expected: コンパイルエラー（`claySlotPalette` が無い）。

- [ ] **Step 3: トークンを差し替える**

`DesignSystem.swift`:
```swift
    /// 画面の地。
    /// クレイの面が浮いて見えるよう、白ではなく濃いめの藤色にする。
    /// 白に近い地では影もハイライトも消え、フラットに見えた(2026-09-25 実機で確認)。
    public static let bgBase = adaptive(light: 0xDCD3F7, dark: 0x1B1636)

    /// カード・セル・モーダルの面。地より明るいクリーム寄りの白
    public static let bgSurface = adaptive(light: 0xF7F2FF, dark: 0x2A2350)
```
`accentSoft` は `adaptive(light: 0xEAE3FF, dark: 0x3A2F73)` に。

`Clay.swift` の面色の節（`claySky` の直後）に追加:
```swift
    /// 空きスロットの面色。添字で循環させ、隣り合うマスが同じ色にならないよう 5 色にする
    /// (2 列なら縦隣りは +2、3 列なら +3。5 はどちらでも割り切れない)。
    /// 順に 空 / 桃 / ミント / ピンク / レモン
    public static let claySlotPalette: [UIColor] = [
        clayAdaptive(light: 0xCFE9F7, dark: 0x2B4356),
        clayAdaptive(light: 0xFFE0C2, dark: 0x5A4030),
        clayAdaptive(light: 0xD3F1DC, dark: 0x2B4A38),
        clayAdaptive(light: 0xF5D6EC, dark: 0x54344A),
        clayAdaptive(light: 0xFFF3B8, dark: 0x5A5030),
    ]

    public static func claySlotColor(at index: Int) -> UIColor {
        let palette = claySlotPalette
        return palette[((index % palette.count) + palette.count) % palette.count]
    }

    /// 空きスロットの「+」と番号。5 色すべての面に対して 3:1 以上になる濃い紫
    public static let claySlotInk = clayAdaptive(light: 0x5B3FD9, dark: 0xCDBFFF)

    /// ボタンの既定の面。暖かいオレンジで、藤色の地から浮く
    public static let clayOrange = clayAdaptive(light: 0xFFB347, dark: 0xE09A3A)
    /// オレンジの上に載せる文字
    public static let onClayOrange = clayAdaptive(light: 0x3D2200, dark: 0x1F1200)
```

`ClaySurface` に厚みを足す。プロパティ:
```swift
    /// 底の厚み。0 より大きいと面の下に shade 色の層を描き、押すと沈む先が見える
    public var baseDepth: CGFloat = 0 { didSet { setNeedsLayout(); applyColors() } }
    private let base = CALayer()
```
`setup()` の `addSubview(body)` の**前**に `layer.addSublayer(base)`（body より下に来るよう先に足す）。`base.cornerCurve = .continuous`。
`layoutSubviews` に:
```swift
        base.frame = bounds.offsetBy(dx: 0, dy: baseDepth)
        base.cornerRadius = cornerRadius
        base.isHidden = baseDepth <= 0
```
`applyColors()` の `.raised` に `base.backgroundColor = dark.cgColor` を足し、影とハイライトを強める:
```swift
        case .raised:
            highlight.colors = [light.withAlphaComponent(1.0).cgColor, light.withAlphaComponent(0).cgColor]
            highlight.locations = [0, 0.5]
            shade.colors = [dark.withAlphaComponent(0.8).cgColor, dark.withAlphaComponent(0).cgColor]
            shade.locations = [0, 0.45]
            base.backgroundColor = dark.cgColor
            layer.shadowColor = dark.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 10 + baseDepth)
            layer.shadowRadius = 14
            layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.7 : 0.45
```
`.recessed` の陰を `dark.withAlphaComponent(0.85)` / locations `[0, 0.5]` に、下端の光を `light.withAlphaComponent(0.9)` に。`shadowPath` は `bounds.offsetBy(dx: 0, dy: baseDepth)` の角丸パスにする。

`ClayButton`: `surface` の生成を `ClaySurface(style: .raised, fill: .clayOrange, cornerRadius: Radius.small)` に、`setTitleColor(.onClayOrange, for: .normal)`、`tintColor = .onClayOrange`。`surface.baseDepth = 6`。`round(symbol:size:fill:)` の既定 `fill` を `.clayOrange` に。押下の沈み `Motion.pressDrop` を `4` に（厚みぶん沈む）。

- [ ] **Step 4: 通ることを確認**

Run: 単一テスト 4 本、続けて Framework とアプリの全テスト
Expected: すべて PASS。`testTextStaysReadableOnPaletteB` が落ちる色があれば、その色の**ダーク値だけ**を暗く、または**ライト値だけ**を明るく寄せて通す（変えた値を報告に書く）。`testClayButtonUsesDarkBoldTitle` は `textPrimary` を期待しているので、`onClayOrange` を期待するよう書き換える。

- [ ] **Step 5: コミット**

件名: 「配色をトイ・クレイに替え、面の膨らみと底の厚みを足す」

---

### Task 2: 空きスロットに番号と色の循環

**Files:**
- Modify: `PhotoKeyboardEx/Board/EmptySlotCell.swift`
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`（`case .empty` で `configure(index:)`）
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Consumes: `UIColor.claySlotColor(at:)`、`UIColor.claySlotInk`
- Produces: `EmptySlotCell.configure(index: Int)`、`EmptySlotCell.numberLabel: UILabel`（テストが見る）

- [ ] **Step 1: 落ちるテストを書く**

`testEmptySlotIsAccessibleAsButton` の直後:
```swift
    /// 空きスロットには「何枚目か」の番号が入り、面の色は添字で循環すること
    @MainActor
    func testEmptySlotShowsItsNumberAndCyclesColor() {
        let cell = EmptySlotCell(frame: CGRect(x: 0, y: 0, width: 180, height: 220))
        cell.configure(index: 3)
        XCTAssertEqual(cell.numberLabel.text, "4", "添字 3 は 4 枚目")
        XCTAssertTrue(cell.surfaceFillForTesting === UIColor.claySlotColor(at: 3))
        cell.configure(index: 8)
        XCTAssertTrue(cell.surfaceFillForTesting === UIColor.claySlotColor(at: 8))
    }

    /// 一覧は空きスロットに自分の添字を渡すこと。ずれると番号が飛ぶ
    @MainActor
    func testBoardPassesSlotIndexToEmptyCells() {
        let board = UIStoryboard(name: "ChildContent", bundle: nil)
            .instantiateInitialViewController() as? ChildContentViewController
        guard let board = board else { return XCTFail("マイボードを組み立てられない") }
        board.loadViewIfNeeded()
        board.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        let window = UIWindow(frame: board.view.bounds)
        window.rootViewController = board
        window.isHidden = false
        board.view.layoutIfNeeded()
        board.collectionView.layoutIfNeeded()
        guard let emptyIndex = board.slots.firstIndex(of: .empty) else { return XCTFail("空きスロットが無い") }
        let cell = board.collectionView.cellForItem(at: IndexPath(item: emptyIndex, section: 0)) as? EmptySlotCell
        XCTAssertEqual(cell?.numberLabel.text, "\(emptyIndex + 1)")
    }
```

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー（`configure(index:)` が無い）。

- [ ] **Step 3: セルを書き換える**

`EmptySlotCell`:
- `surface` の `fill` 既定は `.claySlotColor(at: 0)`、`private(set)` の `var surfaceFillForTesting: UIColor { surface.fill }`
- `plusView` は右上に小さく（`pointSize: 18, weight: .bold`、`tintColor = .claySlotInk`、右上 `Spacing.m` 内側）
- `let numberLabel = UILabel()` を中央に。`font = .scaled(.largeTitle, weight: .heavy)` を `withDesign(.rounded)` で丸く（`UIFont.brand` と同じ要領）、`textColor = .claySlotInk`、`alpha = 0.55`
- `func configure(index: Int)`: `surface.fill = .claySlotColor(at: index)`、`numberLabel.text = "\(index + 1)"`、`accessibilityLabel = LocalizeKey.emptySlotAccessibility.localizedString() + " \(index + 1)"`
- `prepareForReuse` で `numberLabel.text = nil`

`ChildContentViewController` の `cellForItemAt` の `.empty` 分岐:
```swift
        case .empty:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptySlotCell.reuseIdentifier, for: indexPath)
            (cell as? EmptySlotCell)?.configure(index: indexPath.item)
            return cell
```

- [ ] **Step 4: 通ることを確認** — 単一 2 本、アプリ全体。
- [ ] **Step 5: コミット** — 「空きスロットに番号を入れ、色を循環させる」

---

### Task 3: 進み具合のピルを廃止する

**Files:**
- Delete: `PhotoKeyboardEx/Board/BoardProgressView.swift`（pbxproj からも外す）
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`（register、`boundarySupplementaryItems`、`viewForSupplementaryElementOfKind` を削除）
- Modify: `PhotoKeyboardFramework/LocalizeKey.swift`、ja/en strings（`boardProgress` / `boardComplete` を削除）
- Test: `PhotoKeyboardExTests.swift`（`testProgressShowsFilledOverLimit` / `testProgressSaysCompleteAtLimit` を削除、`testProgressHeaderSitsBelowOnboardingHint` を先頭セル基準に書き換え）

- [ ] **Step 1: テストを書き換える**

`testProgressHeaderSitsBelowOnboardingHint` を次に置き換える（名前も変える）:
```swift
    /// 案内行が出ている間、先頭のマスは案内行の下に来ること。重なると押せない
    @MainActor
    func testFirstCellSitsBelowOnboardingHint() {
        let board = UIStoryboard(name: "ChildContent", bundle: nil)
            .instantiateInitialViewController() as? ChildContentViewController
        guard let board = board else { return XCTFail("マイボードを組み立てられない") }
        board.loadViewIfNeeded()
        board.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        board.applyOnboarding(step: .savePhoto)
        let window = UIWindow(frame: board.view.bounds)
        window.rootViewController = board
        window.isHidden = false
        board.view.layoutIfNeeded()
        guard let first = board.collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            return XCTFail("先頭のマスが無い")
        }
        let cellTop = board.collectionView.convert(first.frame, to: board.view).minY
        let hint = board.view.subviews.first { $0 is OnboardingHintView }
        guard let hint = hint, !hint.isHidden else { return XCTFail("案内行が出ていない") }
        XCTAssertGreaterThanOrEqual(cellTop, hint.frame.maxY, "先頭のマスが案内行と重なっている")
    }
```
2 本のピルのテストを削除。

- [ ] **Step 2: 落ちることを確認** — 書き換えたテストは現状でも通る可能性がある。削除後にコンパイルが通ることを目的にするので、Step 3 を進める。

- [ ] **Step 3: 削除する**

pbxproj からの登録解除:
```ruby
require 'xcodeproj'
project = Xcodeproj::Project.open('PhotoKeyboardEx.xcodeproj')
ref = project.files.find { |f| f.path == 'BoardProgressView.swift' }
ref.remove_from_project if ref
project.save
```
`git rm PhotoKeyboardEx/Board/BoardProgressView.swift`。`grep -rn "BoardProgressView\|boardProgress\|boardComplete" --include="*.swift" --include="*.strings" .` が 0 件。

- [ ] **Step 4: 通ることを確認** — Framework とアプリの全テスト。
- [ ] **Step 5: コミット** — 「進み具合のピルを外す。空きスロットの番号が代わりになる」

---

### Task 4: FAB をもっと大きく浮かせる

**Files:**
- Modify: `PhotoKeyboardEx/MainTabViewController.swift:20,231-238`
- Modify: `PhotoKeyboardFramework/Clay.swift`（`ClayButton.round` に `baseDepth` 引数）
- Test: `PhotoKeyboardFrameworkTests.swift`、`PhotoKeyboardExTests.swift`

- [ ] **Step 1: 落ちるテストを書く**

Framework（`testRoundClayButtonMeetsTapTarget` の直後）:
```swift
    /// 丸ボタンは底の厚みを指定でき、面がそのぶん上に浮くこと
    @MainActor
    func testRoundClayButtonCanHaveBaseDepth() {
        let button = ClayButton.round(symbol: Symbol.add, size: 76, baseDepth: 10)
        button.layoutIfNeeded()
        XCTAssertEqual(button.bounds.width, 76)
        XCTAssertEqual(button.baseDepthForTesting, 10)
    }
```
アプリ（`testAddDoneButtonIsClay` の直後）:
```swift
    /// FAB は 72pt 以上で、厚みを持って浮いていること
    @MainActor
    func testFabIsBigAndLifted() {
        let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        let tab = (main as? UINavigationController)?.viewControllers.first as? MainTabViewController ?? main as? MainTabViewController
        guard let tab = tab else { return XCTFail("MainTab を組み立てられない") }
        tab.loadViewIfNeeded()
        tab.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        tab.view.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(tab.fabButton.bounds.width, 72)
        XCTAssertGreaterThan(tab.fabButton.baseDepthForTesting, 0)
    }
```
（`Main.storyboard` の初期 VC の構造は `MainNavigationViewController` → `MainTabViewController` の可能性がある。`instantiateInitialViewController` の戻りを見て、`MainTabViewController` に辿り着く経路を報告に書く。辿れなければ `MainTabViewController` を Storyboard から `instantiateViewController(withIdentifier:)` で取る。ID が無ければ、テストは `ClayButton.round(symbol:size:baseDepth:)` の値検証だけに留め、その旨を報告する）

- [ ] **Step 2: 落ちることを確認** — コンパイルエラー（`baseDepth:` 引数が無い）。

- [ ] **Step 3: 実装**

`ClayButton`:
- `public var baseDepthForTesting: CGFloat { surface.baseDepth }`
- `round(symbol:size:fill:baseDepth:)`: `baseDepth: CGFloat = 6` を足し、`button.surface.baseDepth = baseDepth`（`surface` が private なら内部の setter 経由）
- `ClayButton.commonInit` の `surface.baseDepth = 6` は Task 1 で入れているので、`round` の引数がそれを上書きする形

`MainTabViewController`:
- `var fabButton = ClayButton.round(symbol: Symbol.add, size: 76, baseDepth: 10)`
- `layoutFAB()` の trailing / bottom を `-Spacing.xl`（24）に。FAB のアイコンは `pointSize: 30, weight: .heavy` の `+`（`round` の中で `size >= 72` なら大きい記号を使う、または `setImage` を `layoutFAB` で上書き）

- [ ] **Step 4: 通ることを確認** — 単一 2 本、両方の全テスト。
- [ ] **Step 5: シミュレータで目視** — マイボードを撮り（前計画と同じ手順）、Read で開く。FAB が厚みを持って浮き、空きスロットに番号と色が入り、地が藤色になっていることを確認。見えたことを報告に書く。
- [ ] **Step 6: コミット** — 「FAB を 76pt にして厚みで浮かせる」

---

### Task 5: 実機確認と PR 更新

- [ ] **Step 1:** 前計画 Task 13 Step 1 と同じ手順で実機へ上書きインストール
- [ ] **Step 2:** 利用者に「配色 / 番号スロット / FAB の浮き / 押した手応え」を見てもらう
- [ ] **Step 3:** `git push` して PR #85 の説明に「配色 B へ変更、ピル廃止、番号スロット、FAB 76pt」を追記（`gh pr edit 85 --body`）
