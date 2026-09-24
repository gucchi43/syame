# クレイ質感UI 基盤（段階1〜4）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** クレイ質感の部品層を作り、ボタンとマイボードに適用して、「埋める」体験（空きスロット・進み具合・コンプリート）を出荷できる状態にする。

**Architecture:** `PhotoKeyboardFramework` に `Clay.swift`（面色・`ClaySurface`・`ClayButton`・`Motion`・`Haptic`）を足し、既存のトークン層 `DesignSystem.swift` と並べる。アプリ側は `AuroraButton` の 7 か所を `ClayButton` に置き換え、マイボードは「写真 + 空きスロット」を並べる純粋なスロット計算（`BoardSlots`）を挟んで、常に上限ぶんのマスを描く。

**Tech Stack:** Swift 5 / UIKit / XCTest。プロジェクトへのファイル追加は `xcodeproj` gem（Ruby）。テストは `xcodebuild test`（iPhone 17 シミュレータ）。

**Spec:** `docs/superpowers/specs/2026-09-24-clay-game-ui-design.md`

## Global Constraints

- コードコメント・テスト名の説明・コミットメッセージは日本語。ファイル出力に絵文字を使わない
- コミット作成者は `gucchi43 <acmican43@gmail.com>`（`git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit`）。コミット末尾に `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` と `Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc` を付ける
- 作業ブランチは `feature/clay-game-ui`。master へ直接 push しない
- マスの数は `RealmManager.photoLimit`（現在 8）に従い、画面側で数を直書きしない
- 影・グラデーションは `Clay.swift` の部品だけが持つ。画面側で `layer.shadow*` を直接書かない
- 新しい文言は `LocalizeKey` + `ja.lproj` / `en.lproj` の `Localizable.strings` に両方足す（`testAllLocalizeKeysHaveTranslations` が落ちる）
- キーボード拡張（`PhotoKeyboardExOrigin`）のコードはこの計画では触らない（`MainKBView.xib` の `customClass` 変更だけは例外。Task 8）
- テストコマンド:
  - Framework: `xcodebuild test -project PhotoKeyboardEx.xcodeproj -scheme PhotoKeyboardEx -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PhotoKeyboardFrameworkTests 2>&1 | grep -E "error:|failed -|Executed [0-9]+ tests|TEST (SUCCEEDED|FAILED)" | tail -5`
  - アプリ: 同じコマンドで `-only-testing:PhotoKeyboardExTests`
  - 単一テスト: `-only-testing:PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests/<テスト名>`
- 「Lottie」「マスコット」「レベル」「音」は入れない（spec「やらないこと」）

---

## ファイル構成

| 操作 | パス | 役割 |
|---|---|---|
| 変更 | `DESIGN.md` | 方針の改訂 |
| 作成 | `PhotoKeyboardFramework/Clay.swift` | 面色・`ClaySurface`・`ClayButton`・`Motion`・`Haptic` |
| 変更 | `PhotoKeyboardFramework/DesignSystem.swift` | `Radius` の値変更、`AuroraButton` の削除 |
| 変更 | `PhotoKeyboardFramework/DefaultsKeys.swift` | `hasCelebratedBoardComplete` |
| 変更 | `PhotoKeyboardFramework/LocalizeKey.swift`、`ja.lproj` / `en.lproj` の `Localizable.strings` | `boardProgress`、`boardComplete` |
| 変更 | `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift` | 方針依存テストの削除、クレイ部品のテスト |
| 作成 | `PhotoKeyboardEx/Board/BoardSlots.swift` | 写真数と上限から並びを決める純粋関数 |
| 作成 | `PhotoKeyboardEx/Board/EmptySlotCell.swift` | 空きスロットのセル |
| 作成 | `PhotoKeyboardEx/Board/BoardProgressView.swift` | 「3 / 8」のピル |
| 変更 | `PhotoKeyboardEx/ChildContentViewController.swift` | スロット並び・埋まる演出・コンプリート |
| 変更 | `PhotoKeyboardEx/PhotoCollectionViewCell.swift` | `ClaySurface` で膨らませる |
| 変更 | `PhotoKeyboardEx/MainTabViewController.swift`、`HowToSendViewController.swift`、`PaywallViewController.swift`、`TopViewController.swift`、`UsageViewController.swift`、`AddViewController.swift` | `ClayButton` への置き換え |
| 変更 | `PhotoKeyboardEx/Top.storyboard`、`Add.storyboard`、`Usage.storyboard`、`PhotoKeyboardExOrigin/MainKBView.xib` | `customClass` を `ClayButton` に |
| 変更 | `PhotoKeyboardExTests/PhotoKeyboardExTests.swift` | ボードのテスト |

新しい Swift ファイルは `PhotoKeyboardEx.xcodeproj/project.pbxproj`（objectVersion 54、同期グループ無し）に登録が要る。登録は次の Ruby で行う（Task 3 と Task 9 で使う）。

```ruby
# ruby -e で実行。引数: ターゲット名 グループパス ファイル名
require 'xcodeproj'
target_name, group_path, file_name = ARGV
project = Xcodeproj::Project.open('PhotoKeyboardEx.xcodeproj')
target = project.targets.find { |t| t.name == target_name }
group = project.main_group.find_subpath(group_path, true)
group.set_source_tree('<group>') if group.source_tree.nil?
file_ref = group.new_reference(file_name)
target.add_file_references([file_ref])
project.save
```

---

### Task 1: DESIGN.md の改訂

**Files:**
- Modify: `DESIGN.md:8-33`（決定した方向性）、`DESIGN.md:78-86`（デザイン原則）、`DESIGN.md:184-211`（角丸・影）、`DESIGN.md:431-470`（移行ステップ・やらないこと）

**Interfaces:**
- Produces: 以後のコードコメントが参照する方針文書。コード上の依存は無い

- [ ] **Step 1: 冒頭の「決定した方向性」を差し替える**

`## 決定した方向性` から `## 参照した実測データ` の直前までを、次の内容に置き換える。

```markdown
## 決定した方向性

**ぷっくりしたクレイ質感で、ゲームのような手触りを全画面に通す。**

2026-09-24 に方針を変えた。それまでは「静かなミニマル。器は黙らせ、人格は秩序・動き・言葉に載せる」
を採っていた（下の「参照した実測データ」「現状の診断」はその時点の記録として残す）。
変えた理由と経緯は `docs/superpowers/specs/2026-09-24-clay-game-ui-design.md` にある。要点は次のとおり。

- 器が黙りすぎて道具の楽しさが無かった。触って気持ちよいことが継続の理由になる
- 保存枚数の上限（`RealmManager.photoLimit`）は制約ではなく「埋める対象」として見せる
- 前方針で禁じた影・グラデーションは「参照アプリが使っていない」が理由で、使うと壊れるからではない

前の方針から残すもの:

| 残す | 理由 |
|---|---|
| 藤色をブランドの軸にする | アイコン・ストア画像との連続性 |
| ライト／ダーク両対応 | 端末設定を無視するアプリにしない |
| 4pt 基準の余白、Dynamic Type、SF Symbols | 崩す理由が無い |
| キーボード拡張で Lottie を使わない | メモリ上限。代わりに自前の軽い動きを使う |
| マスコットを UI に出さない | 見本画像とリリースノートに留める |

人格は次の 3 つに載せる。

- **質感** — 膨らんだ面、くぼんだ空きスロット、押すと沈むボタン
- **動き** — 保存した瞬間にマスがぽんと出る、上限まで埋まると波打つ
- **言葉** — マイクロコピー（変更なし）

```

- [ ] **Step 2: 「デザイン原則」を差し替える**

`## デザイン原則` の 5 項目を次に置き換える。

```markdown
## デザイン原則

1. **秩序を崩さない。** グリッドは常に上限ぶんのマスを見せ、枚数で並びを変えない
2. **膨らみは部品が持つ。** 影・ハイライト・グラデーションは `Clay.swift` の部品だけが描く。画面側で `layer.shadow*` を書かない
3. **文字は高コントラスト。** クレイの面は淡いため、面の上には `textPrimary` を置く。白文字を載せない
4. **画像より目立つ UI 要素を置かない。** 面の色はパステルに留め、彩度で主張しない
5. **動きは意味のある瞬間にだけ。** 押した・埋まった・完成した。装飾のための常時アニメーションはしない
```

- [ ] **Step 3: 「角丸」と「影とブラー」を差し替える**

`### 角丸` の本文を次に置き換える（値だけ変える。表や説明の構成は既存に合わせてよい）。

```markdown
### 角丸

`Radius.small = 16`、`Radius.card = 24`。ピルは高さの半分（`applyPillShape`）。
`cornerCurve = .continuous` を必ず付ける（`applyCornerRadius`）。
2 種類とピルだけを使い、`Radius.small / 2` のような派生値を作らない。
```

`### 影とブラー` の本文を次に置き換える。

```markdown
### 影とブラー

**影とグラデーションは `ClaySurface` だけが持つ。** 外側の柔らかい影（下方向、面の `shade` 色）、
上端の内側ハイライト、下端の内側の陰の 3 つで膨らみを作る。`.recessed` は逆向きに配置してくぼませる。
画面側やセル側で `layer.shadowColor` 等を直接書かない。

**ブラー（`UIBlurEffect`）は使わない。** 透明感は面の色と余白で作る。
```

- [ ] **Step 4: 「移行ステップ」と「やらないこと」を差し替える**

`## 移行ステップ` から末尾までを次に置き換える。

```markdown
## 移行ステップ

`docs/superpowers/specs/2026-09-24-clay-game-ui-design.md` の「実装の順番」に従う。

| 段階 | 内容 | 状態 |
|---|---|---|
| 1 | 本書の改訂 | 済 |
| 2 | 部品層（面色・ClaySurface・ClayButton・Motion・Haptic） | |
| 3 | AuroraButton の置き換え、Radius の引き上げ | |
| 4 | マイボード（上限ぶんのマス・埋まる・進み具合・コンプリート） | |
| 5 | 画面の適用（Top / HowToSend / Usage / Add / PhotoDetail / メニュー / 起動画面 / 案内行） | |
| 6 | キーボード（XIB のコード化・セル・Lottie 削除） | |
| 7 | ストアのスクリーンショット撮り直し | |

## やらないこと

- レベル、報酬、鍵の解除、ストリーク
- 音
- マスコットの UI への登場
- 独自フォント、ブラー
- 紙吹雪や全画面の演出（コンプリートは波打ちとピルの変化まで）
- ナビゲーションバーへの追加導線の移動
- 千鳥配置・ウォーターフォール・可変セル高
```

- [ ] **Step 5: 確認とコミット**

Run: `grep -n "影は原則として使わない\|静かなミニマル。器は黙らせ" DESIGN.md`
Expected: 「静かなミニマル。器は黙らせ」は改訂の引用として 1 行だけ残り、「影は原則として使わない」は 0 件。

```bash
git add DESIGN.md
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
デザイン方針をクレイ質感のゲーム的UIへ改める

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 2: 方針に依存する既存テストを消す

**Files:**
- Modify: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift:549-556`

**Interfaces:**
- Produces: なし。後続タスクでトークンを変えても落ちないようにする

- [ ] **Step 1: `testSurfaceSeparationStaysSubtle` を削除する**

`/// 地とカード面の差は意図的にごく小さくしている。` のコメント 2 行と `func testSurfaceSeparationStaysSubtle()` の本体（閉じ括弧まで）を削除する。`testWhiteOnAuroraNeedsShadowToBeReadable` と `testAuroraTextCarriesShadow` は残す（`Aurora` はロゴ周りとトーストに残るため）。`testAuroraButtonUsesBoldTitle` は Task 8 で `AuroraButton` を消すときに一緒に消す。

- [ ] **Step 2: テストが通ることを確認**

Run: Framework のテストコマンド
Expected: `TEST SUCCEEDED`。件数が 1 減っている。

- [ ] **Step 3: コミット**

```bash
git add PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
面の差を小さく縛るテストを外す

クレイ質感では面が地から浮くため、前方針の検証は成り立たない。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 3: 面の色と明暗の派生

**Files:**
- Create: `PhotoKeyboardFramework/Clay.swift`
- Modify: `PhotoKeyboardEx.xcodeproj/project.pbxproj`（Ruby で登録）
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Produces:
  - `UIColor.clayLavender / clayMint / clayPeach / claySky: UIColor`
  - `UIColor.clayHighlight(of: UIColor) -> UIColor`（面より明るい）
  - `UIColor.clayShade(of: UIColor) -> UIColor`（面より暗い）

- [ ] **Step 1: 落ちるテストを書く**

`// MARK: - デザイントークン` の `testTextColorsMeetContrastRequirement` の直後に足す。`contrastRatio` は同ファイルの既存ヘルパー。

```swift
    /// 相対輝度(WCAG 2.1)。明暗の派生が正しい向きかを見る
    private func luminance(_ color: UIColor, dark: Bool) -> CGFloat {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ v: CGFloat) -> CGFloat {
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    /// クレイの面色は、派生したハイライトが面より明るく、陰が面より暗いこと。
    /// 派生を計算で作るので、向きが逆だと全部の部品がへこんで見える
    func testClayHighlightAndShadeGoTheRightWay() {
        let surfaces: [(String, UIColor)] = [("lavender", .clayLavender), ("mint", .clayMint),
                                             ("peach", .clayPeach), ("sky", .claySky)]
        for dark in [false, true] {
            for (name, base) in surfaces {
                let mode = dark ? "ダーク" : "ライト"
                XCTAssertGreaterThan(luminance(UIColor.clayHighlight(of: base), dark: dark),
                                     luminance(base, dark: dark), "\(mode) \(name): ハイライトが面より暗い")
                XCTAssertLessThan(luminance(UIColor.clayShade(of: base), dark: dark),
                                  luminance(base, dark: dark), "\(mode) \(name): 陰が面より明るい")
            }
        }
    }

    /// クレイの面に載せる本文は 4.5:1 を満たすこと。面は淡いので白文字は載せない
    func testTextOnClaySurfacesStaysReadable() {
        for dark in [false, true] {
            for base in [UIColor.clayLavender, .clayMint, .clayPeach, .claySky] {
                XCTAssertGreaterThanOrEqual(contrastRatio(.textPrimary, base, dark: dark), 4.5,
                                            "\(dark ? "ダーク" : "ライト"): クレイの面の上で本文が読めない")
            }
        }
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: 単一テスト `testClayHighlightAndShadeGoTheRightWay`
Expected: コンパイルエラー（`clayLavender` が無い）。

- [ ] **Step 3: `Clay.swift` を作り、プロジェクトに登録する**

```swift
//
//  Clay.swift
//  PhotoKeyboardFramework
//
//  クレイ質感の部品。面の色、膨らむ面(ClaySurface)、押すと沈むボタン(ClayButton)、
//  動き(Motion)、振動(Haptic)をここに集める。影とグラデーションを描くのはこのファイルだけ。
//  方針と根拠は DESIGN.md と docs/superpowers/specs/2026-09-24-clay-game-ui-design.md を参照。
//

import UIKit

// MARK: - 面の色

extension UIColor {
    fileprivate convenience init(clayHex hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255.0,
                  green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                  blue: CGFloat(hex & 0xFF) / 255.0,
                  alpha: 1.0)
    }

    fileprivate static func clayAdaptive(light: UInt32, dark: UInt32) -> UIColor {
        return UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(clayHex: dark) : UIColor(clayHex: light)
        }
    }

    /// 既定の面。藤色系。ボタン、カード
    public static let clayLavender = clayAdaptive(light: 0xD9D0F2, dark: 0x3A3352)
    /// 進み具合のピル、完成の表示
    public static let clayMint = clayAdaptive(light: 0xCDEBDD, dark: 0x27423A)
    /// 空きスロットの「+」、注意喚起
    public static let clayPeach = clayAdaptive(light: 0xF8D9CC, dark: 0x4A342E)
    /// 案内行、補助のバッジ
    public static let claySky = clayAdaptive(light: 0xCFE3F5, dark: 0x2A3A4E)

    /// 面の色を白の方へ寄せる。ダークでは面が暗いぶん寄せ幅を抑え、白飛びを避ける
    public static func clayHighlight(of base: UIColor) -> UIColor {
        return UIColor { traits in
            let amount: CGFloat = traits.userInterfaceStyle == .dark ? 0.20 : 0.35
            return base.resolvedColor(with: traits).clayMixed(with: .white, amount: amount)
        }
    }

    /// 面の色を黒の方へ寄せる。影と下端の陰に使う
    public static func clayShade(of base: UIColor) -> UIColor {
        return UIColor { traits in
            let amount: CGFloat = traits.userInterfaceStyle == .dark ? 0.35 : 0.18
            return base.resolvedColor(with: traits).clayMixed(with: .black, amount: amount)
        }
    }

    /// 2 色を RGB で線形に混ぜる。amount が 1 なら other になる
    fileprivate func clayMixed(with other: UIColor, amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = min(max(amount, 0), 1)
        return UIColor(red: r1 + (r2 - r1) * t,
                       green: g1 + (g2 - g1) * t,
                       blue: b1 + (b2 - b1) * t,
                       alpha: a1)
    }
}
```

登録:

```bash
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("PhotoKeyboardEx.xcodeproj")
target = project.targets.find { |t| t.name == "PhotoKeyboardFramework" }
group = project.main_group.find_subpath("PhotoKeyboardFramework", true)
file_ref = group.new_reference("Clay.swift")
target.add_file_references([file_ref])
project.save
'
grep -c "Clay.swift" PhotoKeyboardEx.xcodeproj/project.pbxproj
```
Expected: `grep` が 3 以上（BuildFile、FileReference、グループの 3 か所）。

- [ ] **Step 4: 通ることを確認**

Run: 単一テスト `testClayHighlightAndShadeGoTheRightWay`、続けて `testTextOnClaySurfacesStaysReadable`
Expected: どちらも PASS。ダークの `textPrimary`（0xF2F1F5）と `clayMint`（0x27423A）の比が 4.5 を切る場合は、`clayMint` のダーク値を `0x22392F` へ下げる。

- [ ] **Step 5: コミット**

```bash
git add PhotoKeyboardFramework/Clay.swift PhotoKeyboardEx.xcodeproj/project.pbxproj PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
クレイの面色4色と、明暗の派生を足す

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 4: 角丸を大きくする

**Files:**
- Modify: `PhotoKeyboardFramework/DesignSystem.swift:30-35`

**Interfaces:**
- Produces: `Radius.small = 16`、`Radius.card = 24`（名前は不変）

- [ ] **Step 1: 落ちるテストを書く**

`testClayHighlightAndShadeGoTheRightWay` の直後に足す。

```swift
    /// クレイの角丸は大きめに固定する。小さいと粘土ではなく厚紙に見える
    func testRadiusIsLargeEnoughForClay() {
        XCTAssertEqual(Radius.small, 16)
        XCTAssertEqual(Radius.card, 24)
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: 単一テスト `testRadiusIsLargeEnoughForClay`
Expected: FAIL（12 と 16 のまま）。

- [ ] **Step 3: 値を変える**

`DesignSystem.swift` の `Radius` を次に置き換える。

```swift
/// 「ピル」と「中程度」の2種類だけを使う。中途半端な角丸と直角を作らない。
/// クレイ質感は角が大きいほど粘土らしく見えるため、以前の 12 / 16 から上げた。
public enum Radius {
    /// 入力欄、小さいカード、ボタン
    public static let small: CGFloat = 16
    /// 画像セル、カード
    public static let card: CGFloat = 24
}
```

- [ ] **Step 4: 全テストを回す**

Run: Framework とアプリのテストコマンドを両方
Expected: どちらも `TEST SUCCEEDED`。`GuideKeyboardStripView` 等で `Radius.small / 2` を使っている箇所は値が 8 になるだけで壊れない。

- [ ] **Step 5: コミット**

```bash
git add PhotoKeyboardFramework/DesignSystem.swift PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
角丸を 16 / 24 に上げる

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 5: Motion と Haptic

**Files:**
- Modify: `PhotoKeyboardFramework/Clay.swift`
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Produces:
  - `Motion.isReducedOverride: Bool?`（テスト用）、`Motion.isReduced: Bool`
  - `Motion.pressDown(_ view: UIView)`、`Motion.release(_ view: UIView)`
  - `Motion.pop(_ view: UIView, delay: TimeInterval = 0, completion: (() -> Void)? = nil)`
  - `Motion.rippleStagger: TimeInterval`
  - `Haptic.Kind { tap, fill, complete }`、`Haptic.driver: HapticDriver`、`Haptic.play(_:)`
  - `protocol HapticDriver { func play(_ kind: Haptic.Kind) }`

- [ ] **Step 1: 落ちるテストを書く**

`// MARK: - デザイントークン` の末尾（`testAllSymbolsExist` の直後）に足す。

```swift
    // MARK: - 動きと振動

    /// テストで振動を記録する
    private final class RecordingHaptic: HapticDriver {
        var played: [Haptic.Kind] = []
        func play(_ kind: Haptic.Kind) { played.append(kind) }
    }

    /// 押すと縮み、離すと戻ること
    @MainActor
    func testPressShrinksAndReleaseRestores() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        Motion.pressDown(view)
        XCTAssertLessThan(view.transform.a, 1.0, "押しても縮んでいない")
        Motion.release(view)
        XCTAssertEqual(view.transform.a, 1.0, accuracy: 0.001, "離しても戻っていない")
    }

    /// 視差効果を減らす設定のときは、縮小も移動もしないこと
    @MainActor
    func testReducedMotionSkipsTransform() {
        Motion.isReducedOverride = true
        defer { Motion.isReducedOverride = nil }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        Motion.pressDown(view)
        XCTAssertEqual(view.transform, .identity, "設定を無視して縮んでいる")
        Motion.pop(view)
        XCTAssertEqual(view.transform, .identity, "設定を無視して出現の縮小をしている")
    }

    /// 出現の動きは 1.0 倍で終わること。途中の 1.05 倍で止まると並びが崩れる
    @MainActor
    func testPopEndsAtIdentity() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let done = expectation(description: "出現の完了")
        Motion.pop(view) { done.fulfill() }
        wait(for: [done], timeout: 3)
        XCTAssertEqual(view.transform.a, 1.0, accuracy: 0.001)
        XCTAssertEqual(view.alpha, 1.0, accuracy: 0.001)
    }

    /// 振動は差し替えた生成器へ届くこと
    func testHapticGoesThroughInjectedDriver() {
        let recorder = RecordingHaptic()
        let previous = Haptic.driver
        Haptic.driver = recorder
        defer { Haptic.driver = previous }
        Haptic.play(.tap)
        Haptic.play(.complete)
        XCTAssertEqual(recorder.played, [.tap, .complete])
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: 単一テスト `testPressShrinksAndReleaseRestores`
Expected: コンパイルエラー（`Motion` が無い）。

- [ ] **Step 3: `Clay.swift` に `Motion` と `Haptic` を足す**

ファイル末尾に追加。

```swift
// MARK: - 動き

/// 押下・出現・完成の動き。時間とバネはここでだけ決める。
/// 「視差効果を減らす」が有効なら縮小と移動を行わず、フェードだけにする。
public enum Motion {
    /// テストから設定を固定するための上書き。nil なら端末の設定に従う
    public static var isReducedOverride: Bool?

    public static var isReduced: Bool {
        return isReducedOverride ?? UIAccessibility.isReduceMotionEnabled
    }

    /// 沈む速さ。指の動きより遅いと重く感じる
    public static let pressDuration: TimeInterval = 0.12
    /// 戻りのバネ。小さいほど大きく揺れる
    public static let pressDamping: CGFloat = 0.55
    /// 沈んだときの縮み
    public static let pressScale: CGFloat = 0.96
    /// 沈んだときの下がり
    public static let pressDrop: CGFloat = 2

    /// 出現の時間とバネ
    public static let popDuration: TimeInterval = 0.45
    public static let popDamping: CGFloat = 0.6
    /// 完成の波で、隣のマスをずらす間隔
    public static let rippleStagger: TimeInterval = 0.05

    /// 押した瞬間。縮めて少し下げる
    public static func pressDown(_ view: UIView) {
        guard !isReduced else { return }
        UIView.animate(withDuration: pressDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            view.transform = CGAffineTransform(scaleX: pressScale, y: pressScale)
                .translatedBy(x: 0, y: pressDrop)
        }
    }

    /// 離した瞬間。バネで元に戻す
    public static func release(_ view: UIView) {
        guard !isReduced else { return }
        // テストではアニメーションの終端を待たずに検証するため、最終値を先に置く
        UIView.animate(withDuration: pressDuration * 3, delay: 0,
                       usingSpringWithDamping: pressDamping, initialSpringVelocity: 0.5,
                       options: [.allowUserInteraction]) {
            view.transform = .identity
        }
        view.transform = .identity
    }

    /// 出現。0.6 倍から 1.05 倍を経て 1.0 へ。
    /// 縮小を使えない設定のときはフェードだけにする
    public static func pop(_ view: UIView, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        if isReduced {
            view.alpha = 0
            UIView.animate(withDuration: popDuration * 0.5, delay: delay, options: []) {
                view.alpha = 1
            } completion: { _ in completion?() }
            return
        }
        view.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        view.alpha = 0
        UIView.animate(withDuration: popDuration * 0.4, delay: delay, options: [.curveEaseOut]) {
            view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            view.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: popDuration * 0.6, delay: 0,
                           usingSpringWithDamping: popDamping, initialSpringVelocity: 0.3,
                           options: []) {
                view.transform = .identity
            } completion: { _ in completion?() }
        }
    }
}

// MARK: - 振動

/// 振動の生成器。テストでは記録用に差し替える
public protocol HapticDriver {
    func play(_ kind: Haptic.Kind)
}

/// 端末の生成器で鳴らす既定の実装
final class SystemHapticDriver: HapticDriver {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    func play(_ kind: Haptic.Kind) {
        switch kind {
        case .tap: light.impactOccurred()
        case .fill: medium.impactOccurred()
        case .complete: notification.notificationOccurred(.success)
        }
    }
}

/// 振動の種類。音は入れない(spec)
public enum Haptic {
    public enum Kind: Equatable {
        /// ボタンを押した
        case tap
        /// マスが埋まった
        case fill
        /// 上限まで埋まった
        case complete
    }

    public static var driver: HapticDriver = SystemHapticDriver()

    public static func play(_ kind: Kind) {
        driver.play(kind)
    }
}
```

- [ ] **Step 4: 通ることを確認**

Run: 単一テスト 4 本（`testPressShrinksAndReleaseRestores`、`testReducedMotionSkipsTransform`、`testPopEndsAtIdentity`、`testHapticGoesThroughInjectedDriver`）
Expected: すべて PASS。

- [ ] **Step 5: コミット**

```bash
git add PhotoKeyboardFramework/Clay.swift PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
押下・出現の動きと振動を部品にする

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 6: ClaySurface

**Files:**
- Modify: `PhotoKeyboardFramework/Clay.swift`
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Produces:
  - `ClaySurface(style: ClaySurface.Style = .raised, fill: UIColor = .clayLavender, cornerRadius: CGFloat = Radius.card)`
  - `ClaySurface.Style { raised, recessed }`
  - `ClaySurface.contentView: UIView`（子ビューはここに載せる）
  - `ClaySurface.fill: UIColor`（変更可）

- [ ] **Step 1: 落ちるテストを書く**

`testHapticGoesThroughInjectedDriver` の直後に足す。

```swift
    // MARK: - ClaySurface

    /// 描画した面の、上端の帯と下端の帯の平均輝度を返す。角は避けて中央 60% だけ見る
    @MainActor
    private func bandLuminance(of view: UIView, dark: Bool) -> (top: Double, bottom: Double) {
        view.overrideUserInterfaceStyle = dark ? .dark : .light
        view.layoutIfNeeded()
        let size = view.bounds.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.magenta.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            view.layer.render(in: context.cgContext)
        }
        guard let cg = image.cgImage else { return (0, 0) }
        let w = cg.width, h = cg.height
        var px = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return (0, 0) }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        func mean(rows: Range<Int>) -> Double {
            var sum = 0.0, n = 0.0
            for y in rows {
                for x in Int(Double(w) * 0.2)..<Int(Double(w) * 0.8) {
                    let i = (y * w + x) * 4
                    sum += 0.2126 * Double(px[i]) + 0.7152 * Double(px[i + 1]) + 0.0722 * Double(px[i + 2])
                    n += 1
                }
            }
            return sum / max(n, 1)
        }
        // 角丸と影を避け、面の内側の上下 12% を見る
        let inset = Int(Double(h) * 0.12)
        return (mean(rows: inset..<(inset * 2)), mean(rows: (h - inset * 2)..<(h - inset)))
    }

    /// 膨らむ面は上端が下端より明るいこと(ハイライトの証明)。ライト・ダーク両方
    @MainActor
    func testRaisedSurfaceIsBrighterAtTop() {
        for dark in [false, true] {
            let surface = ClaySurface(style: .raised)
            surface.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
            let band = bandLuminance(of: surface, dark: dark)
            XCTAssertGreaterThan(band.top, band.bottom + 2,
                                 "\(dark ? "ダーク" : "ライト"): 上端が明るくなっていない \(band)")
        }
    }

    /// くぼむ面は逆に上端が暗いこと
    @MainActor
    func testRecessedSurfaceIsDarkerAtTop() {
        for dark in [false, true] {
            let surface = ClaySurface(style: .recessed)
            surface.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
            let band = bandLuminance(of: surface, dark: dark)
            XCTAssertLessThan(band.top + 2, band.bottom,
                              "\(dark ? "ダーク" : "ライト"): 上端が暗くなっていない \(band)")
        }
    }

    /// 子ビューは contentView に載り、面の大きさに追従すること
    @MainActor
    func testSurfaceContentViewFillsBounds() {
        let surface = ClaySurface()
        surface.frame = CGRect(x: 0, y: 0, width: 150, height: 90)
        surface.layoutIfNeeded()
        XCTAssertEqual(surface.contentView.bounds.size, surface.bounds.size)
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: 単一テスト `testRaisedSurfaceIsBrighterAtTop`
Expected: コンパイルエラー（`ClaySurface` が無い）。

- [ ] **Step 3: `Clay.swift` に `ClaySurface` を足す**

`// MARK: - 動き` の直前に挿入。

```swift
// MARK: - 膨らむ面

/// クレイ質感の面。外側の柔らかい影、上端の内側ハイライト、下端の内側の陰で膨らみを作る。
///
/// 外側の影を持つ層(self, clip なし)と、中身を丸く切る層(body, clip あり)の 2 層で組む。
/// 1 層で clipsToBounds を立てると外側の影が切れる。
/// 子ビューは contentView に載せる。
public final class ClaySurface: UIView {
    public enum Style {
        /// 膨らむ。ボタン、カード
        case raised
        /// くぼむ。空きスロット、入力欄
        case recessed
    }

    public let style: Style
    public var fill: UIColor { didSet { applyColors() } }
    public var cornerRadius: CGFloat { didSet { setNeedsLayout() } }

    /// 子ビューの置き場
    public let contentView = UIView()

    private let body = UIView()
    private let highlight = CAGradientLayer()
    private let shade = CAGradientLayer()

    public init(style: Style = .raised, fill: UIColor = .clayLavender, cornerRadius: CGFloat = Radius.card) {
        self.style = style
        self.fill = fill
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        self.style = .raised
        self.fill = .clayLavender
        self.cornerRadius = Radius.card
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        body.clipsToBounds = true
        body.layer.cornerCurve = .continuous
        addSubview(body)

        // 上端の光と下端の陰。向きは style で決める
        highlight.startPoint = CGPoint(x: 0.5, y: 0)
        highlight.endPoint = CGPoint(x: 0.5, y: 1)
        shade.startPoint = CGPoint(x: 0.5, y: 1)
        shade.endPoint = CGPoint(x: 0.5, y: 0)
        body.layer.addSublayer(highlight)
        body.layer.addSublayer(shade)

        contentView.backgroundColor = .clear
        body.addSubview(contentView)

        layer.cornerCurve = .continuous
        applyColors()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        body.frame = bounds
        body.layer.cornerRadius = cornerRadius
        contentView.frame = body.bounds
        highlight.frame = body.bounds
        shade.frame = body.bounds
        // 影の形を先に決めておくと、レイアウトのたびに影を計算し直さない
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 影と cgColor は自動で明暗に追従しないため、ここで引き直す
        applyColors()
    }

    private func applyColors() {
        let resolvedFill = fill.resolvedColor(with: traitCollection)
        let light = UIColor.clayHighlight(of: fill).resolvedColor(with: traitCollection)
        let dark = UIColor.clayShade(of: fill).resolvedColor(with: traitCollection)
        body.backgroundColor = resolvedFill

        switch style {
        case .raised:
            // 上から光が当たり、下に陰が落ちる
            highlight.colors = [light.withAlphaComponent(0.9).cgColor, light.withAlphaComponent(0).cgColor]
            highlight.locations = [0, 0.45]
            shade.colors = [dark.withAlphaComponent(0.55).cgColor, dark.withAlphaComponent(0).cgColor]
            shade.locations = [0, 0.4]
            layer.shadowColor = dark.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 6)
            layer.shadowRadius = 12
            layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.55 : 0.35
        case .recessed:
            // 上から陰が落ち、下端がわずかに光る。外側の影は持たない
            highlight.colors = [dark.withAlphaComponent(0.6).cgColor, dark.withAlphaComponent(0).cgColor]
            highlight.locations = [0, 0.4]
            shade.colors = [light.withAlphaComponent(0.7).cgColor, light.withAlphaComponent(0).cgColor]
            shade.locations = [0, 0.35]
            layer.shadowOpacity = 0
        }
    }
}
```

- [ ] **Step 4: 通ることを確認**

Run: 単一テスト 3 本（`testRaisedSurfaceIsBrighterAtTop`、`testRecessedSurfaceIsDarkerAtTop`、`testSurfaceContentViewFillsBounds`）
Expected: すべて PASS。`.recessed` で `highlight` と `shade` の名前が逆向きに使われているのは意図（層の位置を再利用し、色だけ入れ替える）。差が 2 に満たない場合は alpha を 0.1 ずつ上げ、必ず両モードで通す。

- [ ] **Step 5: コミット**

```bash
git add PhotoKeyboardFramework/Clay.swift PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
膨らむ面 ClaySurface を足す

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 7: ClayButton

**Files:**
- Modify: `PhotoKeyboardFramework/Clay.swift`
- Test: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Consumes: `ClaySurface`、`Motion`、`Haptic`
- Produces:
  - `ClayButton: UIButton`（Storyboard の `customClass` から使えるよう `UIButton` の派生にする。spec は `UIControl` と書いているが、4 か所が `@IBOutlet weak var ...: UIButton!` で受けているため派生を変えない）
  - `ClayButton.fill: UIColor`
  - `ClayButton.round(symbol: String, size: CGFloat = 44, fill: UIColor = .clayLavender) -> ClayButton`

- [ ] **Step 1: 落ちるテストを書く**

`testSurfaceContentViewFillsBounds` の直後に足す。

```swift
    // MARK: - ClayButton

    /// 押している間は沈み、離すと戻ること。振動は押した瞬間に 1 回
    @MainActor
    func testClayButtonSinksWhileHighlighted() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        let recorder = RecordingHaptic()
        let previous = Haptic.driver
        Haptic.driver = recorder
        defer { Haptic.driver = previous }

        let button = ClayButton(frame: CGRect(x: 0, y: 0, width: 160, height: 48))
        button.setTitle("試す", for: .normal)
        button.isHighlighted = true
        XCTAssertLessThan(button.transform.a, 1.0, "押しても沈んでいない")
        XCTAssertEqual(recorder.played, [.tap])
        button.isHighlighted = false
        XCTAssertEqual(button.transform.a, 1.0, accuracy: 0.001, "離しても戻っていない")
        XCTAssertEqual(recorder.played, [.tap], "離すときにも振動している")
    }

    /// 文字は太字の本文色。クレイの面は淡いため白文字は載せない
    @MainActor
    func testClayButtonUsesDarkBoldTitle() {
        let button = ClayButton(frame: CGRect(x: 0, y: 0, width: 160, height: 48))
        button.setTitle("試す", for: .normal)
        XCTAssertEqual(button.titleColor(for: .normal), UIColor.textPrimary)
        let traits = button.titleLabel?.font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        let weight = (traits?[.weight] as? CGFloat) ?? 0
        XCTAssertGreaterThanOrEqual(weight, UIFont.Weight.semibold.rawValue, "太字になっていない")
    }

    /// 丸ボタンは 44pt 以上で、面が真円になること
    @MainActor
    func testRoundClayButtonMeetsTapTarget() {
        let button = ClayButton.round(symbol: Symbol.add)
        button.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(button.bounds.width, 44)
        XCTAssertEqual(button.bounds.width, button.bounds.height)
        XCTAssertNotNil(button.image(for: .normal))
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: 単一テスト `testClayButtonSinksWhileHighlighted`
Expected: コンパイルエラー（`ClayButton` が無い）。

- [ ] **Step 3: `Clay.swift` に `ClayButton` を足す**

`// MARK: - 動き` の直前（`ClaySurface` の後）に挿入。

```swift
// MARK: - 押すと沈むボタン

/// クレイの面を土台にしたボタン。押すと沈み、離すとバネで戻り、押した瞬間に振動する。
///
/// UIButton の派生にしているのは、Storyboard の customClass と
/// `@IBOutlet weak var button: UIButton!` からそのまま使うため。
/// 面は subview として最背面に置き、UIButton の title / image はその上に載る。
public class ClayButton: UIButton {
    private let surface = ClaySurface(style: .raised, fill: .clayLavender, cornerRadius: Radius.small)

    /// 面の色
    public var fill: UIColor {
        get { surface.fill }
        set { surface.fill = newValue }
    }

    /// 面の角丸。真円にしたいときは layoutSubviews で高さの半分を入れる
    public var cornerRadius: CGFloat {
        get { surface.cornerRadius }
        set { surface.cornerRadius = newValue }
    }

    /// 真円にする。round(symbol:) が立てる
    private var isCircular = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        surface.isUserInteractionEnabled = false
        insertSubview(surface, at: 0)

        setTitleColor(.textPrimary, for: .normal)
        setTitleColor(UIColor.textPrimary.withAlphaComponent(0.4), for: .disabled)
        tintColor = .textPrimary
        // CTA は太字。細いままだと淡い面の上で線が痩せる
        titleLabel?.font = .scaled(.body, weight: .bold)
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        surface.frame = bounds
        if isCircular {
            surface.cornerRadius = bounds.height / 2
        }
    }

    public override var isHighlighted: Bool {
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

    public override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1.0 : 0.6 }
    }

    /// アイコンだけの丸いボタン。キーボードのツールバーや閉じるボタンに使う。44pt 以上
    public static func round(symbol: String, size: CGFloat = 44, fill: UIColor = .clayLavender) -> ClayButton {
        let button = ClayButton(frame: CGRect(x: 0, y: 0, width: size, height: size))
        button.isCircular = true
        button.fill = fill
        button.setImage(.symbol(symbol, textStyle: .body, weight: .semibold), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
        return button
    }
}
```

- [ ] **Step 4: 通ることを確認**

Run: 単一テスト 3 本（`testClayButtonSinksWhileHighlighted`、`testClayButtonUsesDarkBoldTitle`、`testRoundClayButtonMeetsTapTarget`）
Expected: すべて PASS。

- [ ] **Step 5: コミット**

```bash
git add PhotoKeyboardFramework/Clay.swift PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
押すと沈む ClayButton を足す

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 8: AuroraButton を ClayButton に置き換える

**Files:**
- Modify: `PhotoKeyboardEx/MainTabViewController.swift:20,231-251`
- Modify: `PhotoKeyboardEx/HowToSendViewController.swift:18`
- Modify: `PhotoKeyboardEx/PaywallViewController.swift:24`
- Modify: `PhotoKeyboardEx/TopViewController.swift:88-90`、`UsageViewController.swift:65-67`、`AddViewController.swift:113-116`（コメントの整理）
- Modify: `PhotoKeyboardEx/Top.storyboard:40`、`Add.storyboard:78`、`Usage.storyboard:86`、`PhotoKeyboardExOrigin/MainKBView.xib:77`（`customClass="AuroraButton"` → `customClass="ClayButton"`）
- Modify: `PhotoKeyboardFramework/DesignSystem.swift:208-235`（`AuroraButton` 削除）
- Modify: `PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift:582-590`（`testAuroraButtonUsesBoldTitle` 削除）

**Interfaces:**
- Consumes: `ClayButton`（Task 7）
- Produces: `AuroraButton` はコードベースから消える。`AuroraView` と `Aurora` は残る

- [ ] **Step 1: 落ちるテストを書く**

`PhotoKeyboardExTests/PhotoKeyboardExTests.swift` の `testHintOpensHowToSend` の直後に足す。

```swift
    /// 起動直後の画面の開始ボタンはクレイのボタンであること。
    /// Storyboard の customClass を変え忘れると、見た目だけ旧デザインが残る
    @MainActor
    func testTopStartButtonIsClay() {
        let top = UIStoryboard(name: "Top", bundle: nil).instantiateInitialViewController() as? TopViewController
        top?.loadViewIfNeeded()
        XCTAssertTrue(top?.startButton is ClayButton, "開始ボタンが ClayButton ではない")
    }

    /// 追加画面の完了ボタンも同じ
    @MainActor
    func testAddDoneButtonIsClay() {
        let nav = UIStoryboard(name: "Add", bundle: nil).instantiateInitialViewController() as? UINavigationController
        let add = nav?.viewControllers.first as? AddViewController
        add?.loadViewIfNeeded()
        XCTAssertTrue(add?.doneButton is ClayButton, "完了ボタンが ClayButton ではない")
    }

    /// キーボード設定画面の「あとで」の隣の主ボタンも同じ
    @MainActor
    func testUsageNextButtonIsClay() {
        let nav = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController() as? UINavigationController
        let usage = nav?.viewControllers.first as? UsageViewController
        usage?.loadViewIfNeeded()
        XCTAssertTrue(usage?.nextButton is ClayButton, "主ボタンが ClayButton ではない")
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: アプリの単一テスト `testTopStartButtonIsClay`
Expected: FAIL（`AuroraButton` のまま）。

- [ ] **Step 3: Storyboard / XIB の customClass を書き換える**

```bash
sed -i '' 's/customClass="AuroraButton" customModule="PhotoKeyboardFramework"/customClass="ClayButton" customModule="PhotoKeyboardFramework"/' \
  PhotoKeyboardEx/Top.storyboard PhotoKeyboardEx/Add.storyboard PhotoKeyboardEx/Usage.storyboard PhotoKeyboardExOrigin/MainKBView.xib
grep -c 'customClass="ClayButton"' PhotoKeyboardEx/Top.storyboard PhotoKeyboardEx/Add.storyboard PhotoKeyboardEx/Usage.storyboard PhotoKeyboardExOrigin/MainKBView.xib
```
Expected: 4 ファイルとも 1。

- [ ] **Step 4: コードの 3 か所を置き換える**

`MainTabViewController.swift:20`:
```swift
    var fabButton = ClayButton.round(symbol: Symbol.add, size: 56)
```

`MainTabViewController.swift` の `layoutFAB()` を次に置き換える（影の直書きを消す。影は `ClaySurface` が持つ）。
```swift
    func layoutFAB() {
        // 大きさは round(symbol:size:) が制約で持つ。影も面も ClaySurface が持つ
        fabButton.addTarget(self, action: #selector(tapFAB), for: .touchUpInside)
        view.addSubview(fabButton)
        NSLayoutConstraint.activate([
            fabButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Spacing.l),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.l)
        ])
    }
```

`HowToSendViewController.swift:18`:
```swift
    private let doneButton = ClayButton()
```

`PaywallViewController.swift:24`:
```swift
    private let purchaseButton = ClayButton()
```

各画面の `applyCornerRadius(Radius.small)` の呼び出し（Top :90、Usage :67、HowToSend :117、Paywall :94、`KeyboardViewController.swift:174`）はそのまま残してよい（`ClayButton` 自身の layer に角丸が付くだけで、面の角丸は `surface.cornerRadius` が持つ）。ただし `clipsToBounds = true` が外側の影を切るので、**5 か所とも `applyCornerRadius` の行を削除する**。

コメントの整理: `TopViewController.swift:88-89`、`UsageViewController.swift:65`、`AddViewController.swift:113-114`、`KeyboardViewController.swift:173` の「AuroraButton が持つ」というコメントを「ClayButton が持つ」に書き換える。

`AddViewController.swift:116` の `doneButton.alpha = canSubmit ? 1.0 : 0.4` は `ClayButton.isEnabled` が alpha を持つため削除する。

- [ ] **Step 5: `AuroraButton` と、そのテストを削除する**

`DesignSystem.swift` の `/// オーロラで塗るボタン。Storyboard 側でクラスをこれに変えて使う` から `AuroraButton` クラスの閉じ括弧までを削除する。
`PhotoKeyboardFrameworkTests.swift` の `testAuroraButtonUsesBoldTitle` を削除する。

```bash
grep -rn "AuroraButton" --include="*.swift" --include="*.storyboard" --include="*.xib" .
```
Expected: 0 件。

- [ ] **Step 6: 全テストを回す**

Run: Framework とアプリのテストコマンドを両方
Expected: どちらも `TEST SUCCEEDED`。

- [ ] **Step 7: シミュレータで目視**

Run: `xcodebuild -project PhotoKeyboardEx.xcodeproj -scheme PhotoKeyboardEx -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build/sim-dd build 2>&1 | tail -1 && xcrun simctl boot "iPhone 17" 2>/dev/null; xcrun simctl install booted build/sim-dd/Build/Products/Debug-iphonesimulator/PhotoKeyboardEx.app && xcrun simctl launch booted bocchi.PhotoKeyboardEx && sleep 3 && xcrun simctl io booted screenshot build/clay-top.png`
Expected: `build/clay-top.png` を Read で開き、起動直後の画面のボタンが藤色の膨らんだ面で、押せる見た目になっていること。影が四角く切れていないこと。

- [ ] **Step 8: コミット**

```bash
git add -A
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
ボタンをオーロラからクレイに置き換える

オーロラはロゴ周りとトーストにだけ残す。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 9: スロットの並び（BoardSlots）と空きスロットのセル

**Files:**
- Create: `PhotoKeyboardEx/Board/BoardSlots.swift`
- Create: `PhotoKeyboardEx/Board/EmptySlotCell.swift`
- Modify: `PhotoKeyboardEx.xcodeproj/project.pbxproj`（Ruby で 2 ファイル登録）
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Produces:
  - `enum BoardSlot: Equatable { case photo(index: Int); case empty }`
  - `enum BoardSlots { static func make(photoCount: Int, limit: Int) -> [BoardSlot] }`
  - `final class EmptySlotCell: UICollectionViewCell`（`reuseIdentifier`）
  - `ChildContentViewController.slots: [BoardSlot]`（読み取り用。テストが見る）

- [ ] **Step 1: 落ちるテストを書く**

`PhotoKeyboardExTests.swift` の `testAddDoneButtonIsClay` の直後に足す。

```swift
    // MARK: - マイボードのスロット

    /// 写真が上限に満たないぶんは空きスロットで埋め、常に上限ぶんのマスを見せること
    func testSlotsPadWithEmptyUpToLimit() {
        let slots = BoardSlots.make(photoCount: 3, limit: 8)
        XCTAssertEqual(slots.count, 8)
        XCTAssertEqual(Array(slots.prefix(3)), [.photo(index: 0), .photo(index: 1), .photo(index: 2)])
        XCTAssertEqual(Array(slots.suffix(5)), Array(repeating: BoardSlot.empty, count: 5))
    }

    /// 0 枚なら全部が空きスロット。空状態の専用画面は要らない
    func testSlotsAreAllEmptyWhenNothingSaved() {
        XCTAssertEqual(BoardSlots.make(photoCount: 0, limit: 8), Array(repeating: BoardSlot.empty, count: 8))
    }

    /// 上限に達したら空きは無い
    func testSlotsHaveNoEmptyAtLimit() {
        let slots = BoardSlots.make(photoCount: 8, limit: 8)
        XCTAssertEqual(slots.count, 8)
        XCTAssertFalse(slots.contains(.empty))
    }

    /// 上限を超えて保存されていても写真を隠さない(上限を下げた既存利用者を守る)
    func testSlotsNeverHidePhotosBeyondLimit() {
        let slots = BoardSlots.make(photoCount: 9, limit: 8)
        XCTAssertEqual(slots.count, 9)
        XCTAssertEqual(slots.last, .photo(index: 8))
    }

    /// 空きスロットを押すと追加の導線に乗ること。案内行の「保存する」と同じ通知を使う
    @MainActor
    func testTappingEmptySlotRequestsAddPhoto() {
        let board = UIStoryboard(name: "ChildContent", bundle: nil)
            .instantiateInitialViewController() as? ChildContentViewController
        guard let board = board else { return XCTFail("マイボードを組み立てられない") }
        board.loadViewIfNeeded()
        board.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        board.view.layoutIfNeeded()

        let asked = expectation(description: "追加の依頼")
        let token = NotificationCenter.default.addObserver(forName: .requestAddPhoto, object: nil, queue: .main) { _ in
            asked.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(token) }

        guard let emptyIndex = board.slots.firstIndex(of: .empty) else {
            return XCTFail("空きスロットが無い。上限まで埋まった Realm で走っている")
        }
        board.collectionView(board.collectionView, didSelectItemAt: IndexPath(item: emptyIndex, section: 0))
        wait(for: [asked], timeout: 2)
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: アプリの単一テスト `testSlotsPadWithEmptyUpToLimit`
Expected: コンパイルエラー（`BoardSlots` が無い）。

- [ ] **Step 3: `BoardSlots.swift` を作る**

```swift
//
//  BoardSlots.swift
//  PhotoKeyboardEx
//
//  マイボードに並べるマスの種類と並びを決める。Realm も UIKit も知らない。
//

import Foundation

/// マイボードの 1 マス
enum BoardSlot: Equatable {
    /// 保存済みの写真。index は realmData の添字
    case photo(index: Int)
    /// まだ埋まっていないマス。押すと追加へ
    case empty
}

enum BoardSlots {
    /// 写真の枚数と上限から、並べるマスを決める。
    ///
    /// 上限に満たないぶんは空きスロットで埋め、常に上限ぶんのマスを見せる。
    /// 上限を超えて保存されている場合は写真を優先して全部出す
    /// (上限を下げたあとの既存利用者の写真を隠さない)。
    static func make(photoCount: Int, limit: Int) -> [BoardSlot] {
        let photos = (0..<max(photoCount, 0)).map { BoardSlot.photo(index: $0) }
        let empties = Array(repeating: BoardSlot.empty, count: max(limit - photoCount, 0))
        return photos + empties
    }
}
```

- [ ] **Step 4: `EmptySlotCell.swift` を作る**

```swift
//
//  EmptySlotCell.swift
//  PhotoKeyboardEx
//
//  まだ埋まっていないマス。くぼんだ面に「+」を置き、押すと追加へ進む。
//

import UIKit
import PhotoKeyboardFramework

final class EmptySlotCell: UICollectionViewCell {

    static let reuseIdentifier = "EmptySlotCell"

    private let surface = ClaySurface(style: .recessed, fill: .bgSurface, cornerRadius: Radius.card)
    private let plusView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        contentView.backgroundColor = .clear
        surface.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(surface)

        plusView.image = .symbol(Symbol.add, pointSize: 28, weight: .semibold)
        plusView.tintColor = .clayPeach
        plusView.contentMode = .center
        plusView.translatesAutoresizingMaskIntoConstraints = false
        surface.contentView.addSubview(plusView)

        NSLayoutConstraint.activate([
            surface.topAnchor.constraint(equalTo: contentView.topAnchor),
            surface.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            surface.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            plusView.centerXAnchor.constraint(equalTo: surface.contentView.centerXAnchor),
            plusView.centerYAnchor.constraint(equalTo: surface.contentView.centerYAnchor)
        ])
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            isHighlighted ? Motion.pressDown(self) : Motion.release(self)
        }
    }
}
```

登録:
```bash
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("PhotoKeyboardEx.xcodeproj")
target = project.targets.find { |t| t.name == "PhotoKeyboardEx" }
group = project.main_group.find_subpath("PhotoKeyboardEx/Board", true)
group.set_source_tree("<group>")
group.path = "Board" if group.path.nil?
refs = ["BoardSlots.swift", "EmptySlotCell.swift"].map { |f| group.new_reference(f) }
target.add_file_references(refs)
project.save
'
grep -c "BoardSlots.swift\|EmptySlotCell.swift" PhotoKeyboardEx.xcodeproj/project.pbxproj
```
Expected: 6 以上。`PhotoKeyboardEx/Onboarding` グループが既にあるので、同じ形（`path = Board`）で作られていることを `grep -n "path = Board" PhotoKeyboardEx.xcodeproj/project.pbxproj` で確認する。

- [ ] **Step 5: `ChildContentViewController` をスロット並びにする**

次の変更を入れる。

(a) プロパティを足す（`private let refreshControl` の直後）:
```swift
    /// いま並べているマス。写真の枚数と上限から決め、reload のたびに引き直す
    private(set) var slots: [BoardSlot] = []

    private func rebuildSlots() {
        slots = BoardSlots.make(photoCount: realmPhotos?.count ?? 0, limit: RealmManager.photoLimit)
    }
```

(b) `commonInit()` の `collectionView.register(PhotoCollectionViewCell.self, ...)` の直後に:
```swift
        collectionView.register(EmptySlotCell.self, forCellWithReuseIdentifier: EmptySlotCell.reuseIdentifier)
```

(c) `updateEmptyState()` を丸ごと削除し、呼び出し 4 か所（`viewWillAppear`、`reloadAfterPost`、`reloadSaveState`、`realmObjectDidChange`）を `rebuildSlots()` に置き換える。`collectionView.reloadData()` の**前**に `rebuildSlots()` を呼ぶ。`viewWillAppear` は次の形になる:
```swift
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rebuildSlots()
        collectionView.reloadData()
    }
```

(d) データソースを置き換える:
```swift
extension ChildContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slots.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch slots[indexPath.item] {
        case .photo(let index):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? PhotoCollectionViewCell, let photo = savedPhoto(at: index) {
                cell.configure(photo: photo, menu: makeMenu(for: photo))
            }
            return cell
        case .empty:
            return collectionView.dequeueReusableCell(withReuseIdentifier: EmptySlotCell.reuseIdentifier, for: indexPath)
        }
    }
}

extension ChildContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch slots[indexPath.item] {
        case .photo(let index):
            guard let photo = savedPhoto(at: index) else { return }
            showPhotoDetail(rPhoto: photo)
        case .empty:
            // 空きスロットは追加の入口。案内行の「保存する」と同じ導線に乗せる
            NotificationCenter.default.post(name: .requestAddPhoto, object: nil)
        }
    }
}
```

(e) `LocalizeKey.myBoardEmptyTitle` を使う場所が無くなる。`LocalizeKey.swift` の `case myBoardEmptyTitle` と `ja` / `en` の `"myBoardEmptyTitle"` 行を削除する（`testAllLocalizeKeysHaveTranslations` は残った側で落ちないので両方消す）。

- [ ] **Step 6: 通ることを確認**

Run: アプリの単一テスト 5 本（`testSlotsPadWithEmptyUpToLimit`、`testSlotsAreAllEmptyWhenNothingSaved`、`testSlotsHaveNoEmptyAtLimit`、`testSlotsNeverHidePhotosBeyondLimit`、`testTappingEmptySlotRequestsAddPhoto`）、続けて Framework とアプリの全テスト
Expected: すべて PASS。

- [ ] **Step 7: シミュレータで目視**

Task 8 Step 7 と同じ手順で起動し、「はじめる」を押してマイボードへ進んだ画面を `build/clay-board.png` に撮る。
Expected: 見本 1 枚の膨らんだセルと、くぼんだ空きスロット 7 つが 2 列 × 4 行で並ぶ。空きスロットを押すと写真の選択が開く。

- [ ] **Step 8: コミット**

```bash
git add -A
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
マイボードに常に上限ぶんのマスを並べる

保存が足りないぶんは空きスロットで埋め、空状態の専用画面は廃止する。
空きスロットは押すと追加へ進む。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 10: 写真セルをクレイにする

**Files:**
- Modify: `PhotoKeyboardEx/PhotoCollectionViewCell.swift:68-124`
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Consumes: `ClaySurface`、`Motion`
- Produces: `PhotoCollectionViewCell` の見た目だけ。`configure(photo:menu:)`、`infoHeight`、`titleLabel`、`photoImageView`、`menuButton` の名前は変えない（既存テストが参照）

- [ ] **Step 1: 落ちるテストを書く**

`testVeryLongTitleStopsAtTwoLines` の直後に足す。

```swift
    /// 写真セルは膨らんだ面の上に載ること。押すと沈む
    @MainActor
    func testPhotoCellSitsOnRaisedSurfaceAndSinks() {
        Motion.isReducedOverride = false
        defer { Motion.isReducedOverride = nil }
        let metrics = ChildContentViewController.gridMetrics(containerWidth: 393)
        let cell = PhotoCollectionViewCell(frame: CGRect(x: 0, y: 0, width: metrics.itemWidth, height: metrics.rowHeight))
        cell.layoutIfNeeded()
        XCTAssertTrue(cell.contentView.subviews.contains { $0 is ClaySurface }, "面が ClaySurface ではない")
        cell.isHighlighted = true
        XCTAssertLessThan(cell.transform.a, 1.0, "押しても沈んでいない")
        cell.isHighlighted = false
        XCTAssertEqual(cell.transform.a, 1.0, accuracy: 0.001)
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: アプリの単一テスト `testPhotoCellSitsOnRaisedSurfaceAndSinks`
Expected: FAIL（`ClaySurface` が無い）。

- [ ] **Step 3: セルを組み替える**

`PhotoCollectionViewCell` に `private let surface = ClaySurface(style: .raised, fill: .bgSurface, cornerRadius: Radius.card)` を足し、`setupSubviews()` を次に置き換える。制約の付け先を `contentView` から `surface.contentView` に変える以外、寸法と説明コメントは現行を保つ。

```swift
    private func setupSubviews() {
        contentView.backgroundColor = .clear
        surface.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(surface)

        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.backgroundColor = .bgBase
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        // 面の角丸の内側に画像を収める。面より小さい角丸にすると角が四角く見える
        photoImageView.layer.cornerRadius = Radius.card
        photoImageView.layer.cornerCurve = .continuous
        photoImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        titleLabel.applyTextStyle(.footnote)
        titleLabel.numberOfLines = PhotoCollectionViewCell.titleLineLimit
        // 折り返しモードにする。.byTruncatingTail のような切り詰めモードだと
        // numberOfLines を増やしても折り返さず、1行で省略されたままになる。
        // 行数を超えたぶんの末尾の省略記号は UILabel が自分で付ける。
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 画像の上に重なるため、写真の明暗に関わらず読める必要がある。
        // 面の下地を敷いて、その上に暗いアイコンを置く。
        menuButton.setImage(.symbol(Symbol.more, textStyle: .footnote, weight: .semibold), for: .normal)
        menuButton.tintColor = .accent
        menuButton.backgroundColor = .bgSurface
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        let host = surface.contentView
        host.addSubview(photoImageView)
        host.addSubview(titleLabel)
        host.addSubview(menuButton)

        let menuSize: CGFloat = 28
        NSLayoutConstraint.activate([
            surface.topAnchor.constraint(equalTo: contentView.topAnchor),
            surface.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            surface.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            photoImageView.topAnchor.constraint(equalTo: host.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            // 画像は正方形。可変にすると同じ行の2つのセルで高さが揃わない
            photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor),

            menuButton.topAnchor.constraint(equalTo: host.topAnchor, constant: Spacing.s),
            menuButton.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -Spacing.s),
            menuButton.widthAnchor.constraint(equalToConstant: menuSize),
            menuButton.heightAnchor.constraint(equalToConstant: menuSize),

            titleLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: Spacing.s),
            titleLabel.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: Spacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -Spacing.m),
            // 上下とも等号で留めて、ラベルの高さを情報エリアから決める。
            // 上限(lessThanOrEqualTo)にすると高さが UILabel の intrinsicContentSize 任せになり、
            // preferredMaxLayoutWidth が未設定のため1行ぶんに潰れて2行目が出ない。
            // 情報エリアは infoHeight で行数ぶん確保してあるので、ここは割り当てるだけでよい。
            titleLabel.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -Spacing.s)
        ])

        menuButton.applyCornerRadius(menuSize / 2)
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            isHighlighted ? Motion.pressDown(self) : Motion.release(self)
        }
    }
```

`contentView.applyCornerRadius(Radius.card)`（旧 :70）は削除する（clip が外側の影を切る）。

- [ ] **Step 4: 通ることを確認**

Run: アプリの全テスト
Expected: `TEST SUCCEEDED`。題名 2 行のテスト（`renderedLineCount` 系）が通ること。落ちる場合は `titleLabel` の制約先が `host` になっているかを確認する。

- [ ] **Step 5: シミュレータで目視**

Task 9 Step 7 と同じ手順でマイボードを撮る。
Expected: 写真セルが膨らみ、下に影が落ちている。セルとセルの影が隣に被っても読める。

- [ ] **Step 6: コミット**

```bash
git add -A
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
写真セルを膨らんだ面に載せる

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 11: 進み具合のピル

**Files:**
- Create: `PhotoKeyboardEx/Board/BoardProgressView.swift`
- Modify: `PhotoKeyboardEx.xcodeproj/project.pbxproj`（Ruby で登録）
- Modify: `PhotoKeyboardFramework/LocalizeKey.swift`、`ja.lproj` / `en.lproj` の `Localizable.strings`
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`（ヘッダとして差し込む）
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`

**Interfaces:**
- Produces:
  - `LocalizeKey.boardProgress`（"%d / %d"）、`LocalizeKey.boardComplete`
  - `final class BoardProgressView: UICollectionReusableView` with `func apply(filled: Int, limit: Int)` and `var label: UILabel`
  - `BoardProgressView.reuseIdentifier`、`BoardProgressView.elementKind`

- [ ] **Step 1: 落ちるテストを書く**

`testPhotoCellSitsOnRaisedSurfaceAndSinks` の直後に足す。

```swift
    // MARK: - 進み具合

    /// 埋まった数と上限を「3 / 8」の形で出すこと
    @MainActor
    func testProgressShowsFilledOverLimit() {
        let view = BoardProgressView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        view.apply(filled: 3, limit: 8)
        XCTAssertEqual(view.label.text, LocalizeKey.boardProgress.localizedString(3, 8))
        XCTAssertEqual(view.label.text, "3 / 8")
    }

    /// 上限まで埋まったら「コンプリート」に変わること
    @MainActor
    func testProgressSaysCompleteAtLimit() {
        let view = BoardProgressView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        view.apply(filled: 8, limit: 8)
        XCTAssertEqual(view.label.text, LocalizeKey.boardComplete.localizedString())
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: アプリの単一テスト `testProgressShowsFilledOverLimit`
Expected: コンパイルエラー（`BoardProgressView` が無い）。

- [ ] **Step 3: 文言を足す**

`LocalizeKey.swift` の `case onboardingHintAllowFullAccess` の直後に:
```swift
    /// マイボードの進み具合。"%d / %d"
    case boardProgress
    /// 上限まで埋まったとき
    case boardComplete
```

`ja.lproj/Localizable.strings` の末尾に:
```
"boardProgress" = "%d / %d";
"boardComplete" = "コンプリート";
```

`en.lproj/Localizable.strings` の末尾に:
```
"boardProgress" = "%d / %d";
"boardComplete" = "Complete";
```

- [ ] **Step 4: `BoardProgressView.swift` を作り、登録する**

```swift
//
//  BoardProgressView.swift
//  PhotoKeyboardEx
//
//  マイボードの上に出す「3 / 8」のピル。上限まで埋まると「コンプリート」に変わる。
//

import UIKit
import PhotoKeyboardFramework

final class BoardProgressView: UICollectionReusableView {

    static let reuseIdentifier = "BoardProgressView"
    static let elementKind = "BoardProgressHeader"

    let label = UILabel()
    private let pill = ClaySurface(style: .raised, fill: .clayMint, cornerRadius: Radius.small)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        pill.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pill)

        label.applyTextStyle(.subheadline, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.contentView.addSubview(label)

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: centerXAnchor),
            pill.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s),
            pill.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s),
            label.topAnchor.constraint(equalTo: pill.contentView.topAnchor, constant: Spacing.s),
            label.bottomAnchor.constraint(equalTo: pill.contentView.bottomAnchor, constant: -Spacing.s),
            label.leadingAnchor.constraint(equalTo: pill.contentView.leadingAnchor, constant: Spacing.xl),
            label.trailingAnchor.constraint(equalTo: pill.contentView.trailingAnchor, constant: -Spacing.xl)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pill.cornerRadius = pill.bounds.height / 2
    }

    func apply(filled: Int, limit: Int) {
        if filled >= limit {
            label.text = LocalizeKey.boardComplete.localizedString()
        } else {
            label.text = LocalizeKey.boardProgress.localizedString(filled, limit)
        }
    }
}
```

登録（Task 9 の Ruby と同じ形で `BoardProgressView.swift` を `PhotoKeyboardEx/Board` に足す）。

- [ ] **Step 5: 一覧のヘッダにする**

`ChildContentViewController.commonInit()` に:
```swift
        collectionView.register(BoardProgressView.self,
                                forSupplementaryViewOfKind: BoardProgressView.elementKind,
                                withReuseIdentifier: BoardProgressView.reuseIdentifier)
```

`createGridLayout()` の `let section = NSCollectionLayoutSection(group: group)` の直後に:
```swift
            // 進み具合のピルを一覧の頭に置き、スクロールに乗せる
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(56)),
                elementKind: BoardProgressView.elementKind,
                alignment: .top)
            section.boundarySupplementaryItems = [header]
```

データソース拡張に足す:
```swift
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: BoardProgressView.reuseIdentifier,
                                                                   for: indexPath)
        (view as? BoardProgressView)?.apply(filled: realmPhotos?.count ?? 0, limit: RealmManager.photoLimit)
        return view
    }
```

- [ ] **Step 6: 通ることを確認**

Run: アプリの単一テスト 2 本、続けて Framework とアプリの全テスト（`testAllLocalizeKeysHaveTranslations` が文言の追加漏れを拾う）
Expected: すべて PASS。

- [ ] **Step 7: コミット**

```bash
git add -A
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
マイボードの頭に進み具合のピルを出す

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 12: 埋まる演出とコンプリート

**Files:**
- Modify: `PhotoKeyboardFramework/DefaultsKeys.swift`（`hasCelebratedBoardComplete`）
- Modify: `PhotoKeyboardEx/Board/BoardSlots.swift`（新しく増えた写真の特定）
- Modify: `PhotoKeyboardEx/ChildContentViewController.swift`
- Test: `PhotoKeyboardExTests/PhotoKeyboardExTests.swift`、`PhotoKeyboardFrameworkTests/PhotoKeyboardFrameworkTests.swift`

**Interfaces:**
- Consumes: `Motion.pop`、`Motion.rippleStagger`、`Haptic`
- Produces:
  - `GroupeDefaults.hasCelebratedBoardComplete() -> Bool`、`markBoardCompleteCelebrated()`
  - `BoardSlots.newlyAdded(previous: Set<String>, current: [String]) -> [Int]`（増えた写真の添字）
  - `BoardSlots.shouldCelebrate(filled: Int, limit: Int, hasCelebrated: Bool) -> Bool`

- [ ] **Step 1: 落ちるテストを書く**

`PhotoKeyboardExTests.swift` の `testProgressSaysCompleteAtLimit` の直後に:

```swift
    // MARK: - 埋まる演出

    /// 直前に無かった写真だけを「増えた」とみなすこと。並び替えや削除では出さない
    func testNewlyAddedFindsOnlyUnknownIds() {
        let previous: Set<String> = ["a", "b"]
        XCTAssertEqual(BoardSlots.newlyAdded(previous: previous, current: ["a", "b", "c"]), [2])
        XCTAssertEqual(BoardSlots.newlyAdded(previous: previous, current: ["b", "a"]), [])
        XCTAssertEqual(BoardSlots.newlyAdded(previous: previous, current: ["a"]), [])
    }

    /// 上限に達した瞬間だけ祝い、二度目は出さないこと
    func testCelebrateOnlyOnceAtLimit() {
        XCTAssertTrue(BoardSlots.shouldCelebrate(filled: 8, limit: 8, hasCelebrated: false))
        XCTAssertFalse(BoardSlots.shouldCelebrate(filled: 7, limit: 8, hasCelebrated: false))
        XCTAssertFalse(BoardSlots.shouldCelebrate(filled: 8, limit: 8, hasCelebrated: true))
        XCTAssertTrue(BoardSlots.shouldCelebrate(filled: 9, limit: 8, hasCelebrated: false),
                      "上限を超えていても未祝なら祝う")
    }
```

`PhotoKeyboardFrameworkTests.swift` の `testOnboardingFlagsAreOnBeforeFirstRunAndOffAfterDone` の直後に:

```swift
    /// マイボードの完成を祝った記録が残ること
    func testBoardCompleteCelebrationIsRemembered() {
        let defaults = GroupeDefaults.shared
        defaults.sharedDefaults.removeObject(forKey: "hasCelebratedBoardComplete")
        XCTAssertFalse(defaults.hasCelebratedBoardComplete())
        defaults.markBoardCompleteCelebrated()
        XCTAssertTrue(defaults.hasCelebratedBoardComplete())
        defaults.sharedDefaults.removeObject(forKey: "hasCelebratedBoardComplete")
    }
```

- [ ] **Step 2: 落ちることを確認**

Run: アプリの単一テスト `testNewlyAddedFindsOnlyUnknownIds`
Expected: コンパイルエラー（`newlyAdded` が無い）。

- [ ] **Step 3: 記録と純粋関数を足す**

`DefaultsKeys.swift` の `Keys` に `case hasCelebratedBoardComplete` を足し、`markOnboardingCelebrated()` の直後に:
```swift
    /// マイボードが上限まで埋まった祝いを出したか。出すのは一度きり
    public func hasCelebratedBoardComplete() -> Bool {
        return sharedDefaults.bool(forKey: Keys.hasCelebratedBoardComplete.rawValue)
    }

    public func markBoardCompleteCelebrated() {
        sharedDefaults.set(true, forKey: Keys.hasCelebratedBoardComplete.rawValue)
    }
```

`BoardSlots.swift` の `enum BoardSlots` に:
```swift
    /// 直前の一覧に無かった写真の添字。保存直後に「ぽんと出す」マスを決める。
    /// 通知は id を持たないため、前後の id の差で見つける
    static func newlyAdded(previous: Set<String>, current: [String]) -> [Int] {
        return current.enumerated().compactMap { previous.contains($0.element) ? nil : $0.offset }
    }

    /// 上限まで埋まった瞬間に一度だけ祝う
    static func shouldCelebrate(filled: Int, limit: Int, hasCelebrated: Bool) -> Bool {
        return !hasCelebrated && filled >= limit
    }
```

- [ ] **Step 4: 画面に組み込む**

`ChildContentViewController` に:

(a) プロパティ:
```swift
    /// 直前に並べていた写真の id。増えたマスを見つけるために持つ
    private var knownPhotoIds: Set<String> = []
```

(b) `rebuildSlots()` を次に置き換える:
```swift
    private func rebuildSlots() {
        slots = BoardSlots.make(photoCount: realmPhotos?.count ?? 0, limit: RealmManager.photoLimit)
    }

    /// 並べ直したあと、増えたマスを出し、上限に達していれば祝う
    private func animateChanges() {
        let currentIds = (realmPhotos.map { Array($0) } ?? []).map { $0.id }
        let added = BoardSlots.newlyAdded(previous: knownPhotoIds, current: currentIds)
        knownPhotoIds = Set(currentIds)

        for index in added {
            guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else { continue }
            Motion.pop(cell)
        }
        if !added.isEmpty {
            Haptic.play(.fill)
        }

        let filled = currentIds.count
        guard BoardSlots.shouldCelebrate(filled: filled, limit: RealmManager.photoLimit,
                                         hasCelebrated: GroupeDefaults.shared.hasCelebratedBoardComplete())
        else { return }
        GroupeDefaults.shared.markBoardCompleteCelebrated()
        celebrateComplete()
    }

    /// 左上から順に弾ませ、振動で締める。紙吹雪や全画面の演出はしない(spec)
    private func celebrateComplete() {
        let ordered = collectionView.indexPathsForVisibleItems.sorted()
        for (offset, indexPath) in ordered.enumerated() {
            guard let cell = collectionView.cellForItem(at: indexPath) else { continue }
            Motion.pop(cell, delay: Motion.rippleStagger * Double(offset))
        }
        let total = Motion.rippleStagger * Double(ordered.count) + Motion.popDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            Haptic.play(.complete)
        }
    }
```

(c) `viewWillAppear` の `collectionView.reloadData()` の直後に `knownPhotoIds = Set((realmPhotos.map { Array($0) } ?? []).map { $0.id })` を入れ、初回表示で全部が「増えた」扱いにならないようにする。

(d) `reloadAfterPost` を次に置き換える（保存直後はここに来る）:
```swift
    @objc func reloadAfterPost(notification: Notification) -> Void {
        rebuildSlots()
        collectionView.reloadData()
        // reloadData の直後はセルがまだ無い。レイアウトを確定させてから動かす
        collectionView.layoutIfNeeded()
        animateChanges()
    }
```

`reloadSaveState`（削除の経路）と `realmObjectDidChange` は `rebuildSlots()` + `reloadData()` の後に `knownPhotoIds` を現状で更新するだけにし、演出は出さない。

- [ ] **Step 5: 通ることを確認**

Run: アプリの単一テスト 2 本、Framework の `testBoardCompleteCelebrationIsRemembered`、続けて両方の全テスト
Expected: すべて PASS。

- [ ] **Step 6: シミュレータで通しの目視**

Task 8 Step 7 と同じ手順で起動し、次を確かめて `build/clay-fill.png`（保存直後）と `build/clay-complete.png`（上限到達時）を撮る。
1. 写真を 1 枚保存する → そのマスがぽんと出て、ピルが「2 / 8」になる
2. 上限まで保存する → セルが左上から順に弾み、ピルが「コンプリート」になる
3. アプリを再起動しても再度は弾まない

Expected: 3 つとも観察できる。1 のあと「保存しました」のトーストと重なって見えにくければ、`MainTabViewController.finishToast` のトースト位置を `.top` から `.bottom` に変える（1 行の変更に留める）。

- [ ] **Step 7: コミット**

```bash
git add -A
git -c user.name=gucchi43 -c user.email=acmican43@gmail.com commit -m "$(cat <<'EOF'
保存したマスをぽんと出し、上限まで埋まったら一度だけ祝う

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

### Task 13: 実機確認と PR

**Files:**
- なし（確認のみ）

- [ ] **Step 1: 実機に入れる**

```bash
xcodebuild -project PhotoKeyboardEx.xcodeproj -scheme PhotoKeyboardEx -configuration Debug -destination 'platform=iOS,id=00008140-001544A83E13801C' -derivedDataPath build/device-dd build 2>&1 | grep -E "error:|BUILD" | tail -2
xcrun devicectl device install app --device 00008140-001544A83E13801C build/device-dd/Build/Products/Debug-iphoneos/PhotoKeyboardEx.app 2>&1 | grep bundleID
```
Expected: `BUILD SUCCEEDED` と `bundleID: bocchi.PhotoKeyboardEx`。上書きインストールなので保存画像は消えない。

- [ ] **Step 2: 利用者に確認してもらう**

次の 4 点を利用者に見てもらう。
- ライトとダークの両方で、面の膨らみと影が自然か
- ボタンを押したときの沈みと振動が心地よいか（強すぎ／弱すぎ）
- 空きスロットのくぼみが「押せる」と分かるか
- 保存直後の「ぽん」と、コンプリートの波

戻りがあれば `Clay.swift` の定数（`Motion.pressScale`、`ClaySurface.applyColors` の alpha、影の `shadowRadius`）だけを調整し、テストが通ることを確認して 1 コミットにまとめる。

- [ ] **Step 3: PR を作る**

```bash
git push -u origin feature/clay-game-ui
gh pr create --base master --head feature/clay-game-ui --title "クレイ質感の部品層を作り、ボタンとマイボードに適用する" --body "$(cat <<'EOF'
設計: docs/superpowers/specs/2026-09-24-clay-game-ui-design.md
計画: docs/superpowers/plans/2026-09-25-clay-game-ui-foundation.md（段階 1〜4）

- 方針を「クレイ質感のゲーム的UI」へ改訂
- 面色 4 色、ClaySurface、ClayButton、Motion、Haptic を PhotoKeyboardFramework に追加
- AuroraButton を ClayButton に置き換え（オーロラはロゴ周りとトーストに残す）
- マイボードに常に上限ぶんのマスを並べ、空きスロット・進み具合・コンプリートを追加

段階 5（画面の適用）と 6（キーボード）は別 PR。

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01F7QH6xrqxC4zXHUs9JkGfc
EOF
)"
```

---

## この計画に含めないもの（別計画）

- spec の段階 5: Top / HowToSend / Usage / Add / PhotoDetail / サイドメニュー / 起動画面 / 案内行への適用（Usage と Add のコード化を含む）
- spec の段階 6: キーボード拡張の XIB のコード化、セルのクレイ化、Lottie の削除、`ClaySurface` の軽量版（事前描画の影画像）
- spec の段階 7: ストアのスクリーンショット撮り直し
- 鍵付きスロット（`SlotKind.locked`）。`BoardSlot` に case を足すだけで描けるが、`PremiumStore.isAvailable` が偽の間は不要
