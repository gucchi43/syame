# クレイ質感のゲーム的UIへの刷新

作成日: 2026-09-24

## 背景と決定

2.2.0 で初回導線が整ったのを受け、見た目の方針を変える。

これまでの `DESIGN.md` は「静かなミニマル。器は黙らせ、人格は秩序・動き・言葉に載せる」を採り、
影・グラデーション・装飾を禁じていた。本書はそれを覆し、
**ぷっくりしたクレイ質感（粘土のような柔らかい 3D）で、ゲームのような手触りを全画面に通す**。

### なぜ変えるか

- ミニマルの根拠だった「量を売っていない」「写真の隣で器は黙る」は今も正しいが、
  実機で触った結果、**器が黙りすぎて道具の楽しさが無い**。保存して貼るだけのアプリは、
  触って気持ちよいことが継続の理由になる
- 保存枚数の上限（`RealmManager.photoLimit`、現在 8）は制約ではなく「埋める対象」として見せた方が前向きになる。
  これは `DESIGN.md` が「10 マスグリッドと空きスロット」として書きながら未実装だったもの。
  マスの数は 10 ではなく上限の定数に従う
- 前方針で禁じた影・グラデーションは「参照アプリが使っていない」が理由で、
  使うと壊れるからではない。クレイは影と内側の光で成立するため、この禁止を解く

### 前の方針から残すもの

| 残す | 理由 |
|---|---|
| 藤色をブランドの軸にする | アイコン・ストア画像との連続性 |
| ライト／ダーク両対応 | 端末設定を無視するアプリにしない |
| 4pt 基準の余白、Dynamic Type、SF Symbols | 崩す理由が無い |
| キーボード拡張で Lottie を使わない | メモリ上限。代わりに自前の軽い動きを使う |
| マスコットを UI に出さない | 見本画像とリリースノートに留める（利用者の決定） |

### 決めたこと（利用者と確認済み）

| 論点 | 決定 |
|---|---|
| 質感 | クレイ型。内側のハイライトと柔らかい影で膨らんで見える |
| ゲーム性の範囲 | 見た目と動き、コレクションの完成感まで。レベル・報酬・解除は入れない |
| キーボード | アプリと同じ見た目にする。ホストの明暗への追従は残す |
| 配色 | 藤色を軸に、面の色としてパステル 4 色を足す |
| 音・振動 | 振動のみ。音は入れない |
| 進め方 | トークン起点で部品を差し替え、Storyboard 固定の画面は順にコード化する |

## 部品層（`PhotoKeyboardFramework/DesignSystem.swift`）

既存のトークン（`Spacing` / `Radius` / 色 / `UIFont.scaled` / `Symbol`）はそのまま残し、
以下を足す。本体アプリとキーボード拡張の両方が使う。

### 角丸

`Radius` を 12 / 16 から **16 / 24** に上げる。名前は変えない。
ピル（`applyPillShape`）はそのまま。

### 面の色

`UIColor` に 4 色を足す。すべてライト・ダーク両値。

| 名前 | 用途 |
|---|---|
| `clayLavender` | 既定の面。藤色系。ボタン、カード |
| `clayMint` | 進み具合のピル、完成の表示 |
| `clayPeach` | 空きスロットの `+`、注意喚起 |
| `claySky` | 案内行、補助のバッジ |

各色から `highlight`（面より明るい）と `shade`（面より暗い）を**計算で派生**させる
（`UIColor.clayHighlight(of:)` / `clayShade(of:)`）。手で 12 色を選ばない。
ダークモードではハイライトの alpha を下げ、影は地に沈める。

既存の `accent` / `onAccent` / `accentSoft` は文字と選択状態に使い続ける。
`Aurora` はロゴまわり（`MainTabViewController` の titleView とトースト）にだけ残し、
ボタンからは外す。

### `ClaySurface: UIView`

膨らんで見える面。

- 外側の柔らかい影: 下方向、ぼかし大、色は面の `shade`
- 上端の内側ハイライト: 白の薄いグラデーション（上から下へ消える）
- 下端の内側の陰: `shade` の薄いグラデーション（下から上へ消える）
- 角丸は `Radius.card`（既定）または `Radius.small`。`cornerCurve = .continuous`

`clipsToBounds` を切ると外側の影が消えるため、**影を持つ器（clip なし）と、
中身を丸く切る面（clip あり）の 2 層**で組む。`layoutSubviews` でグラデーションの
frame を追従させる。

`style` として `.raised`（膨らむ。既定）と `.recessed`（くぼむ。空きスロット・入力欄）を持つ。
`.recessed` は外側の影を持たず、内側の陰を上端に、ハイライトを下端に置く。

### `ClayButton: UIControl`

`ClaySurface(.raised)` を土台にしたボタン。

- 押下: 0.96 倍に縮み、2pt 下がり、外側の影が縮む
- 離す: バネで戻る（`Motion.press`）
- 押下時に `Haptic.tap`
- 文字は `UIFont.scaled(.body, weight: .bold)`、色は `textPrimary`。
  クレイの面は淡いため白文字を載せない
- アイコンのみの丸ボタン（`ClayButton.round(symbol:)`）を用意し、
  キーボードのツールバーと PhotoDetail の閉じるボタンに使う。**44pt 以上**

`AuroraButton` を使っている 7 か所（Top / Add / Usage / MainKBView / MainTab の FAB /
HowToSend / Paywall）をこれに置き換える。

### `Motion`

| 名前 | 用途 | 内容 |
|---|---|---|
| `press` | 押下と戻り | 0.12 秒で沈み、damping 0.55 のバネで戻る |
| `pop` | 出現 | 0.6 倍から 1.05 倍を経て 1.0 へ。damping 0.6 |
| `ripple` | 完成の波 | `pop` を 0.05 秒ずつずらして順に |

`UIAccessibility.isReduceMotionEnabled` が真なら、縮小と移動を行わずフェードだけにする。
判定は 1 か所（`Motion.isReduced`）に置き、テストで差し替えられるようにする。

### `Haptic`

| 名前 | 生成器 |
|---|---|
| `tap` | `UIImpactFeedbackGenerator(style: .light)` |
| `fill` | `UIImpactFeedbackGenerator(style: .medium)` |
| `complete` | `UINotificationFeedbackGenerator` の `.success` |

生成器は `Haptic.driver` として差し替え可能にし、テストでは記録用の実装を注入する。
キーボード拡張からも同じものを使う。既存の `KeyboardViewController` の生成器はこれに統合する。

## マイボード（`ChildContentViewController` / `PhotoCollectionViewCell`）

コレクションの完成感の核。

### 常に上限の数だけマスを見せる

上限は `RealmManager.photoLimit`（現在 8）。保存が 3 枚なら「写真 3 + 空きスロット 5」を並べ、2 列 × 4 行に収まる。
現在の「0 枚なら顔アイコンの空状態」（`ChildContentViewController.swift` の backgroundView）は
廃止し、空きスロットが空状態を兼ねる。列数は 2 列のまま。

データ源は `RealmManager.shared.realmData`（見本を含む。見本は今どおり 1 マス消費する）。
この画面でマスの数を直書きしない。上限が変われば並びも変わる。

### セルの種類

| 種類 | 見た目 | 操作 |
|---|---|---|
| 写真 | `ClaySurface(.raised)`。画像は角丸で内側に収め、下に題名 2 行（現行維持）。右上の「…」はクレイの小さい丸 | タップで 0.96 倍に沈み、詳細へ |
| 空きスロット | `ClaySurface(.recessed)`。中央に `clayPeach` の薄い `+` | タップで追加へ（`.requestAddPhoto` を投げる） |

有料プランで上限が伸びる将来のため、上限を超えるマスを「鍵付きスロット」として同じ部品で
描けるよう `SlotKind` に `.locked` を用意するが、**今回は描かない**（`PremiumStore.isAvailable`
が偽の間は存在しない扱い）。

### 動き

- **埋まる**: 保存直後（`.finishUpload`）、そのマスを `Motion.pop` で出す。`Haptic.fill`
- **進み具合**: ナビバー直下に `clayMint` のピルで「3 / 8」。マスが埋まった瞬間にカウントアップ
- **コンプリート**: 上限まで埋まった瞬間、セルを左上から `Motion.ripple` で順に弾ませ、
  ピルを「コンプリート」に変え、`Haptic.complete`。
  二度目以降は出さない。記録は `GroupeDefaults` に `hasCelebratedBoardComplete` として持つ

ピルの文言は `Localizable.strings` に足す（`boardProgress`（"%d / %d"）と `boardComplete`）。

## 画面への適用

順番どおりに進める。各画面は単体で出荷できる状態にする。

| 順 | 画面 | やること |
|---|---|---|
| 1 | Top | CTA を `ClayButton` に。図の中のピル・キーボード面は Guide 部品がトークン経由なので自動で変わる。ロゴのフェードは維持 |
| 2 | HowToSend | 番号バッジをクレイの丸に。CTA 差し替え |
| 3 | Usage | **コード化**。Storyboard の固定 13pt を Dynamic Type に。設定行の図のスイッチをクレイに。制約の付け替えで図を差し込んでいる現行コードは不要になる |
| 4 | Add | **コード化**。TextField を `ClaySurface(.recessed)` に。高さ 80 の全幅ボタンを `ClayButton` に |
| 5 | PhotoDetail | 閉じるボタンを `ClayButton.round` に。字幕帯をクレイ面に |
| 6 | サイドメニュー | 行をクレイのカードに。選択状態を沈みで表現。`UIColor.gray` の直書きを消す |
| 7 | 起動画面 | 旧紫（#240440）を `bgBase` に。ロゴのみ |
| 8 | オンボーディング案内行 | `OnboardingHintView` を `claySky` のピルに。完了ダイアログは `UIAlertController` のまま |

FAB（`MainTabViewController`）は `ClayButton.round` に置き換える。
ナビゲーションバーへ移す案（旧 `DESIGN.md` 段階 5）は採らない。
空きスロットが追加の入口を兼ねるため、FAB は「どこからでも追加できる」補助に格下げする。

Paywall（`PaywallViewController` / `PlanButton`）は `PremiumStore.isAvailable` が偽の間は出ないが、
部品の差し替えだけは行い、見た目の不一致を残さない。

## キーボード拡張（`PhotoKeyboardExOrigin`）

- `MainKBView.xib` を**コードに置き換える**。XIB が参照している存在しない IBAction 2 つ
  （`tapHomeButton:` / `tapNotFullButton:`）はこれで消える。SwiftUI の `Link` を重ねて
  URL を開く現行の仕組みは維持する
- ツールバーのボタン 4 つ（home / grid / next keyboard / 文字盤切替）を `ClayButton.round`
  の **44pt** にする（現在 36pt）
- `PhotoCollectionViewCell.xib` を**コード化**。`ClaySurface(.raised)` の小さい版（`Radius.small`）。
  画像は正方形に揃える
- **Lottie を外す**。コピー時は「セルが沈む（`Motion.press`）→ `COPY` のクレイバッジが
  `Motion.pop` で出る → 戻る」の自前アニメにする。`Haptic.tap`。
  `project.pbxproj` の拡張ターゲットから Lottie のリンクを外す
- `TextCollectionViewCell` も同じ面にする
- 地の色は `bgBase`。**`keyboardAppearance` への追従（`applyHostKeyboardAppearance`）は残す**。
  iOS 26 の角丸パネル対策で地を透明にしている箇所は、実機で検証して必要なら地だけ透明のまま面をクレイにする
- **メモリ**: 影は `layer.shadowPath` + `shadowRadius` を使わず、**事前に描いた影画像**
  （`UIImage.resizableImage`）を `UIImageView` で敷く。セル数 × ぼかしのリアルタイム描画を避ける。
  同じ理由で `ClaySurface` は拡張向けに `.lightweight` フラグを持ち、グラデーションを
  1 枚の事前描画画像に置き換える

## テスト

### 消すもの

`PhotoKeyboardFrameworkTests` のうち方針に依存するもの。

- 「bgSurface と bgBase の差が 1.5 未満」
- 「オーロラの白文字には影が必須」「AuroraButton は太字」（`AuroraButton` を使わなくなるため）

コントラスト（4.5:1 / 3:1）の検証は残す。クレイの面に載せる `textPrimary` も同じ基準で見る。

### 足すもの

| 対象 | 検証 |
|---|---|
| `ClaySurface(.raised)` | 描画して、上端の帯が下端の帯より明るい（ハイライトの証明）。ライト・ダーク両方 |
| `ClaySurface(.recessed)` | 上端が下端より暗い |
| `ClayButton` | 押下で `transform` の scale が 1 未満。離すと 1 に戻る。`Motion.isReduced` が真なら 1 のまま |
| `Haptic` | 記録用 driver を注入し、`ClayButton` 押下で `tap` が 1 回記録される |
| 面の色 | 4 色それぞれで `clayHighlight` が面より明るく、`clayShade` が面より暗い |
| マイボード | 3 枚保存で `photoLimit` 個のセルが描かれる（写真 3・空き 5）。上限まで埋めるとコンプリート表示。記録済みなら二度出ない |
| キーボードのセル | コピー時に `COPY` バッジが出る。Lottie の参照が無い |
| Reduce Motion | `Motion.isReduced` 差し替えで `pop` の scale が変わらない |

### 直すもの

既存のピクセル検証（`containsColor`、特にダークの許容差 4）は面がベタでなくなるため、
「面の色が存在する」から「面の中央付近の色がトークンに近い」へ判定位置を絞る。
`renderedLineCount`（題名 2 行）はそのまま使える。

## やらないこと

- レベル、報酬、鍵の解除、ストリーク
- 音
- マスコットの UI への登場
- 独自フォント、ブラー
- 紙吹雪や全画面の演出（コンプリートは波打ちとピルの変化まで）
- ナビゲーションバーへの追加導線の移動

## 実装の順番

前の段階が後の段階の前提になっている。

| 段階 | 内容 | 出荷できるか |
|---|---|---|
| 1 | `DESIGN.md` の改訂（本書の要約を反映） | - |
| 2 | 部品層（色・`ClaySurface`・`ClayButton`・`Motion`・`Haptic`）とテスト | 見た目は変わらない |
| 3 | `AuroraButton` の置き換え（7 か所）、`Radius` の引き上げ | できる |
| 4 | マイボード（上限ぶんのマス・埋まる・進み具合・コンプリート） | できる |
| 5 | 画面の適用 1〜8 | 画面ごとにできる |
| 6 | キーボード（XIB のコード化・セル・Lottie 削除） | できる |
| 7 | ストアのスクリーンショットを撮り直す | 6 の後 |

段階 3 以降は各段階を 1 つの PR にする。
