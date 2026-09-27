# マイボードを「ずっと続くノート」にする

作成日: 2026-09-27

## 背景と決定

2026-09-24 に「クレイ質感のゲーム的UI」を実装したが（PR #85）、実機で「色・雰囲気が地味・安っぽい」と判断され、閉じてストックした（ブランチ `feature/clay-game-ui`、画像と HTML は `一時素材/design/`）。

代わりに、**日記帳に写真を貼ってメモしている感じ**をオマージュする。参考は利用者が示した 3 枚（黒いマスキングテープで紙焼きを留めた日記帳、方眼のリング綴じ、クリーム紙のスクラップ）。

モックで決めたこと:

| 論点 | 決定 | モック |
|---|---|---|
| 紙 | 方眼ノート（J1） | https://claude.ai/artifact/TASSVvccF7gSQTZfhDTy9m |
| 並べ方 | 整った 2 列をやめ、**縦に続く 1 冊のノートに無造作に貼ってストック**していく | https://claude.ai/artifact/1jiF8gGbiAWxzS8oWBqN1C |
| 無造作さ | 形 4 種・角度 ±9°・重なりあり・テープ 4 種 + 小物 | 同上 |
| 書体 | 日本語 Zen Kurenaido、英字（ロゴ・日付・ラベル）Special Elite | https://claude.ai/artifact/MrV9DK3twM8rvkLeSKagy8 |
| ダーク | 黒い紙のノート + 白ペン・白テープ | 上のモックの 02 |
| 進み具合 | 数字のピルは置かない。鉛筆で「あと n 枚」 | 同上 |
| キーボード | フィルムのコンタクトシート風（**本書の範囲外**。後で別の設計書） | - |

HTML は `一時素材/design/`（`periperi-journal.html`、`periperi-scatter.html`、`periperi-fonts.html`）。

### 本書の範囲

- マイボード（`ChildContentViewController` とセル）
- 紙・インク・テープの色と書体のトークン、書体の同梱
- 案内行（付箋）と追加ボタン（丸いシール）
- 並び順を安定させるための `RealmPhoto` の日時
- `DESIGN.md` の改訂

範囲外（後で別の設計書）: Top / HowToSend / Usage / Add / PhotoDetail / サイドメニュー / 起動画面、キーボード拡張。これらは今の見た目のまま残るが、色トークンの差し替えで地の色だけは紙になる。

## 見た目の決まり

### 紙とインク（`PhotoKeyboardFramework/DesignSystem.swift`）

既存の色トークンの**名前は残し、値を紙とインクに置き換える**。他の画面も地の色だけは揃う。

| トークン | ライト | ダーク | 役割 |
|---|---|---|---|
| `bgBase` | #F8F7F2 | #1B1A1E | 紙 |
| `bgSurface` | #FFFEFB | #242328 | ポラロイドの枠、メモの下地 |
| `textPrimary` | #1E1C1A | #EFEBE3 | ペン |
| `textSecondary` | 下記「鉛筆」と同じ | 同左 | 鉛筆 |
| `accent` | #1C1B19 | #EDEAE2 | テープ（黒 / 白） |
| `onAccent` | #F8F7F2 | #1B1A1E | テープの上の文字 |
| `accentSoft` | #F6E7A1 | #5A5230 | 付箋 |

新しく足すもの（`PhotoKeyboardFramework/Journal.swift`、後述）:

| トークン | ライト | ダーク | 役割 |
|---|---|---|---|
| `paperGrid` | #7882961F（alpha 0.12） | #C8CDDC1F | 方眼の線 |
| `pencil` | #6E695F | #9A958B | 「次はここ」「あと n 枚」、日付 |
| `tapeWhite` | #EDEAE2 | #EDEAE2 | 白テープ |
| `tapeClear` | #FFFFFF73 | #FFFFFF38 | 透明テープ |
| `kraft` | #E9DFC6 | #CDBF9E | 荷札・星のシール |

**鉛筆は文字として読めること。** モックの鉛筆 #9A958B は紙に対して約 2.8:1 で本文基準（4.5:1）に届かない。見た目より読めることを優先し、ライトは #6E695F まで濃くする（テストで 4.5:1 以上を固定）。

写真は**加工しない**。モックが灰色なのは仮の画像だからで、利用者の写真はそのままの色で貼る。

### 書体

| 用途 | 書体 | サイズの基準 |
|---|---|---|
| 題名・メモ・付箋・「次はここ」 | Zen Kurenaido | `UIFont.TextStyle` に合わせて Dynamic Type に追従 |
| ロゴ・日付・荷札 | Special Elite | 同上 |

Zen Kurenaido は SIL Open Font License、Special Elite は Apache License 2.0。どちらも同梱してよい。`.ttf` をアプリに同梱し、`Info.plist` の `UIAppFonts` に登録する。ライセンス文を `PhotoKeyboardEx/Fonts/` に置く。

`UIFont.journal(_ style:)` と `UIFont.label(_ style:)` を足す（`UIFontMetrics` で拡大縮小）。書体が読み込めない場合は、日本語は `UIFont.brand` の丸ゴシック、英字は `Courier` に落とす。

キーボード拡張はこの段階では書体を使わない（拡張は後の設計書で扱う。メモリ上限があるため、拡張に日本語書体を入れるかはそこで決める）。

### 小物の種類

すべて実在する文房具だけにする。

| 種類 | 描き方 |
|---|---|
| 紙焼き | 写真の周りに余白なし。影は薄く |
| ポラロイド | `bgSurface` の枠。下の余白が広い |
| ちぎった切れ端 | 上辺がぎざぎざ（`CAShapeLayer` のマスク） |
| 横長 | 3:2 に切り抜く |
| テープ | 黒・白・透明・長い の 4 種。上辺中央、または対角の 2 隅 |
| クリップ | 線で描いたゼムクリップ |
| 荷札 | `kraft` の荷札に日付（Special Elite） |
| 星のシール | `kraft` の星 |

テープと小物はベクタで描く（画像を持たない）。

## ノートの組み方

### 並び順

**貼った順に上から下へ。** 新しい写真はいちばん下に貼られる。

今の `RealmManager.realmData` は並びを指定しておらず、Realm は削除のあとに並びが変わることがある。貼った順を保つため、`RealmPhoto` に `pastedAt: Date` を足し、`realmData` をこれで並べる。

- スキーマ版を 1 → 2 に上げる。移行では、既存の写真に**今の並び順どおり**に 1 秒ずつ増える日時を入れる（今見えている順番を変えない）
- 見本画像も同じ扱い（最初の 1 枚として一番上に来る）
- キーボード拡張も同じ Realm を開くので、同じリリースで両方が版 2 になる。拡張だけ古いまま版 2 を開くことはない（同じバンドルで配る）

### 貼り方を決める（`JournalPlacement`）

写真ごとの形・大きさ・角度・テープ・左右の位置は、**写真の id から決まる**。乱数を使わないので、同じ写真はいつ開いても同じ貼り方になり、1 枚足しても前の写真は動かない。

- id の文字列から **FNV-1a** で 64 ビットの値を作り、そこから各要素を取り出す。Swift の `hashValue` は起動のたびに変わるので使わない
- 形: 紙焼き 40% / ポラロイド 25% / 切れ端 20% / 横長 15%
- 大きさ: ノートの幅に対して 大 0.62 / 中 0.50 / 小 0.40
- 角度: −9°〜+9°（0.5° 刻み）
- テープ: 黒 / 白 / 透明 / 長い / 2 隅 / クリップ
- 左右: 前の写真と反対側に寄せ、そこから ±12pt ずらす
- 縦: 前の写真の下端から、写真の高さの 0〜20% だけ食い込ませて置く（重なり）
- 小物（荷札・星）: 約 1/5 の写真に 1 つ。荷札は日付が変わった最初の 1 枚に付ける

計算は Realm も UIKit も知らない純粋な関数にする（入力: id の列、ノートの幅、各写真の縦横比 → 出力: 各写真の枠と角度と種類）。

### 題名（メモ）

- 写真の脇に、空いている側へ手書きで置く。脇に 110pt 以上空いていなければ写真の下に置く
- Zen Kurenaido、最大 3 行、超えたら末尾を省略
- 角度は写真と逆向きに少しだけ（±3°）

### 「次はここ」と「あと n 枚」

- 上限（`RealmManager.photoLimit`、今は 8）に達していなければ、いちばん下の写真の下に鉛筆の点線の枠を 1 つだけ置き、「次はここ」と書く。押すと追加へ進む（`.requestAddPhoto`）
- 枠の脇に鉛筆で「あと n 枚」
- 上限に達したら、枠の代わりに「このノートはいっぱい」と書く
- 「いっぱい」の判定は保存できるかどうか（`PhotoQuota.isBoardFull` = `!canSave`）にそろえる。プレミアムでは出さず、常に「次はここ」で残り枚数も書かない
- 数字のピル、並んだ空きスロットは置かない

### ノートの上

- ロゴ「periperi」は Special Elite で、ラベルライターのテープのように白い帯に黒字（ダークは反転）
- ロゴの下に最初の写真を貼った日付と「p.1」
- 案内行（`OnboardingHintView`）は**黄色い付箋**にする。少し傾け、右下を折る。出ている間は一覧を押し下げる（今の inset の処理を持ち込む）

### 追加ボタン

- 付箋を丸く切ったシール（`accentSoft`）、直径 64pt、−6° 傾ける、内側に点線の円
- 押すとシールが少し沈んで戻る、軽い振動

### 動き

| 場面 | 動き |
|---|---|
| 写真を貼った直後 | 写真がテープごと上から 40pt 落ちてきて、少し回りながら所定の角度で止まる。振動 1 回 |
| ノートを開いたとき | 動かさない |
| 上限まで貼ったとき | 「このノートはいっぱい」が鉛筆で書かれるように左から現れる。振動 1 回。一度きり |
| 押したとき | 写真・枠・シールが少し沈む |

「視差効果を減らす」が有効なら、落ちる・回るをやめてフェードだけにする。

### 写真の操作

- タップで詳細へ（今と同じ）
- 今のセル右上の「…」ボタンは置かない（紙の上にボタンがあると日記帳に見えない）。**長押しでメニュー**（コピー / 削除）を出す。`UIContextMenuInteraction` を使う
- VoiceOver: 写真は「題名、写真」と読み、カスタムアクションでコピーと削除を出す。「次はここ」は「写真を追加」のボタン

## 作り

### 新しいファイル

| パス | 役割 |
|---|---|
| `PhotoKeyboardFramework/Journal.swift` | 紙・インク・テープの色、`UIFont.journal` / `UIFont.label`、テープと小物の描画 |
| `PhotoKeyboardEx/Journal/JournalPlacement.swift` | id から貼り方を決める純粋関数（FNV-1a 含む） |
| `PhotoKeyboardEx/Journal/JournalLayout.swift` | `UICollectionViewLayout` の派生。`JournalPlacement` の結果を枠と `transform` にする |
| `PhotoKeyboardEx/Journal/PastedPhotoCell.swift` | 写真 1 枚 + テープ + 題名 |
| `PhotoKeyboardEx/Journal/NextSpotView.swift` | 「次はここ」の枠と「あと n 枚」（追加ボタンとして振る舞う） |
| `PhotoKeyboardEx/Journal/PaperBackgroundView.swift` | 方眼の紙（`CAReplicatorLayer` か描画で線を引く） |
| `PhotoKeyboardEx/Fonts/*.ttf`、`OFL.txt` | 書体 |

### クレイのブランチから持ち込むもの

`feature/clay-game-ui` のうち、見た目に依存しないものだけを持ち込む（cherry-pick ではなく、必要な部分を書き写す）。

- `Motion`（押下・出現・視差効果の設定）と `Haptic`（振動と差し替え）
- 案内行が出ている間に一覧を押し下げる処理（`viewDidLayoutSubviews`、先頭で静止しているときだけ位置を合わせる、`applyOnboarding` で `setNeedsLayout`）
- 保存の知らせを追加シートが閉じてから出す処理、並びが変わっていない Realm 通知で作り直さない処理
- それぞれのテスト

持ち込まないもの: `ClaySurface`、`ClayButton`、クレイの色、`BoardSlots`（並べ方が変わるため `JournalPlacement` に置き換える）、`EmptySlotCell`、`BoardProgressView`。`AuroraButton` はこの段階では置き換えない（範囲外の画面が使っているため）。

### 変わる既存ファイル

- `PhotoKeyboardFramework/Photo.swift`: `pastedAt`
- `PhotoKeyboardFramework/RealmManager.swift`: スキーマ版 2 と移行、`realmData` を `pastedAt` で並べる
- `PhotoKeyboardFramework/DesignSystem.swift`: 色の値
- `PhotoKeyboardEx/ChildContentViewController.swift`: 新しいレイアウトとセル、長押しメニュー、「次はここ」
- `PhotoKeyboardEx/Onboarding/OnboardingHintView.swift`: 付箋
- `PhotoKeyboardEx/MainTabViewController.swift`: 追加ボタン、ロゴ
- `PhotoKeyboardEx/Info.plist`: `UIAppFonts`
- `PhotoKeyboardEx/PhotoCollectionViewCell.swift`: 使わなくなるので削除（テストは `PastedPhotoCell` に書き換える）

## テスト

| 対象 | 検証 |
|---|---|
| FNV-1a | 決まった文字列に対して決まった値（既知のベクタで固定）。起動をまたいで同じ |
| `JournalPlacement` | 同じ id の列なら同じ結果。末尾に 1 つ足しても、それまでの写真の枠と角度が変わらない。角度が −9°〜+9°、重なりが高さの 20% 以下、ノートの幅からはみ出さない。形の出現割合がおおむね指定どおり（id 1000 個） |
| `JournalLayout` | 各写真の `transform` が指定の角度。`collectionViewContentSize` の高さが最後の要素の下端 + 余白。上限未満なら「次はここ」がいちばん下 |
| 並び順 | `pastedAt` で並ぶ。移行で既存の並びが保たれる（版 1 の Realm を作って開き直す） |
| 色 | ペンと鉛筆が紙に対してライト・ダークとも 4.5:1 以上。付箋の上のペンも 4.5:1 以上 |
| 書体 | 2 書体が読み込めて `UIFont(name:)` が nil でない。読み込めないときに代わりの書体が返る |
| 題名 | 3 行で止まる（今の `renderedLineCount` の検証を書き体に合わせて移す） |
| 長押し | セルに `UIContextMenuInteraction` があり、メニューにコピーと削除がある |
| VoiceOver | 写真にラベルとカスタムアクション 2 つ。「次はここ」がボタンとして読める |
| 動き | 視差効果を減らす設定で、貼る動きの回転と移動が起きない |
| 持ち込んだもの | クレイのブランチで通っていた案内行・保存の知らせ・Realm 通知のテストがそのまま通る |

## やらないこと

- 写真の色を加工する（モノクロ化・セピア化）
- 利用者が写真の位置や角度を指でずらす（今回は決定的な自動配置だけ）
- ページめくり、複数冊のノート（上限を増やす有料の話と一緒に後で考える）
- キーボード拡張と、マイボード以外の画面の見た目
- マスコットの UI への登場

## 実装の順番

| 段階 | 内容 |
|---|---|
| 1 | `DESIGN.md` の改訂、色トークン、書体の同梱と `UIFont.journal` / `label` |
| 2 | `pastedAt` とスキーマ移行、`realmData` の並び |
| 3 | `JournalPlacement`（純粋関数）とテスト |
| 4 | `JournalLayout`、`PastedPhotoCell`、`PaperBackgroundView`、`NextSpotView` |
| 5 | `ChildContentViewController` の組み替え、長押しメニュー、VoiceOver |
| 6 | クレイから持ち込む処理（案内行の押し下げ、保存の知らせ、Realm 通知）、付箋と丸いシール、ロゴ |
| 7 | 貼る動きと「いっぱい」の演出 |
| 8 | 実機で確認 |
