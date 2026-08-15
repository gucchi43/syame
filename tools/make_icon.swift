// ペリペリのアイコンとロゴマークを生成する。
//
// 図形は「セールマーク状のトゲトゲしたシールが8割貼られ、右下の2割がめくれて折り返っている」形。
// 名前の由来である「ペリペリ剥がす」を、文字を使わずに形だけで示している。
//
// 質感は Y2K のホログラムシール。銀地にオーロラの虹が流れ、周囲に白い縁が付く。
// 縁はシールの型抜きを模したもので、明るい地の上でも図形の輪郭が保たれる。
//
// 使い方:
//   swift tools/make_icon.swift
// カレントディレクトリに PNG を書き出すので、リポジトリ直下から実行してアセットへ差し替える。
//
// 手描きではなく計算で作っているため、トゲの本数もめくれの角度も定数を変えれば作り直せる。

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let spikes = 16
let rOuter = size * 0.40
let rInner = size * 0.335
let center = CGPoint(x: size / 2, y: size / 2)

/// 型抜きの白縁の太さ。線は中心揃えで引くため、外に出るのは半分
let borderWidth = size * 0.038

/// トゲトゲの外形。外半径と内半径を交互に打つ
let burst: CGPath = {
    let path = CGMutablePath()
    let step = Double.pi / Double(spikes)
    for i in 0..<(spikes * 2) {
        let r = i.isMultiple(of: 2) ? rOuter : rInner
        let a = Double(i) * step - Double.pi / 2
        let p = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
        i == 0 ? path.move(to: p) : path.addLine(to: p)
    }
    path.closeSubpath()
    return path
}()

/// 折り目の直線を n・p = d で表す。n は「めくれる側」を向く単位法線。
/// d を大きくするほど折り返る面積が減る。0.66 でおよそ全体の2割にあたる
let foldAngle = -Double.pi / 4
let n = CGPoint(x: cos(foldAngle), y: sin(foldAngle))
let d = (rOuter + rInner) / 2 * 0.66

/// 折り目を挟んで法線と逆側だけを覆う十分に大きい多角形。貼られている側のクリップに使う
let adheredSide: CGPath = {
    let L = size * 4
    let origin = CGPoint(x: center.x + n.x * d, y: center.y + n.y * d)
    let t = CGPoint(x: -n.y, y: n.x)
    let path = CGMutablePath()
    path.move(to: CGPoint(x: origin.x + t.x * L, y: origin.y + t.y * L))
    path.addLine(to: CGPoint(x: origin.x - t.x * L, y: origin.y - t.y * L))
    path.addLine(to: CGPoint(x: origin.x - t.x * L - n.x * L, y: origin.y - t.y * L - n.y * L))
    path.addLine(to: CGPoint(x: origin.x + t.x * L - n.x * L, y: origin.y + t.y * L - n.y * L))
    path.closeSubpath()
    return path
}()

/// 折り返った裏面。折り目を軸に鏡映し、折り目の中点まわりに少し回して機械的に見せない
let flap: CGPath = {
    let mid = CGPoint(x: center.x + n.x * d, y: center.y + n.y * d)
    let offset = center.x * n.x + center.y * n.y + d
    var t = CGAffineTransform(a: 1 - 2 * n.x * n.x, b: -2 * n.x * n.y,
                              c: -2 * n.x * n.y, d: 1 - 2 * n.y * n.y,
                              tx: 2 * offset * n.x, ty: 2 * offset * n.y)
        .concatenating(CGAffineTransform(translationX: -mid.x, y: -mid.y))
        .concatenating(CGAffineTransform(rotationAngle: -0.10))
        .concatenating(CGAffineTransform(translationX: mid.x, y: mid.y))
    return withUnsafePointer(to: &t) { burst.copy(using: $0)! }
}()

func rgb(_ hex: UInt32, _ alpha: Double = 1) -> CGColor {
    CGColor(srgbRed: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255, alpha: alpha)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!

/// オーロラの色順。銀から青紫、桃、金、若草、水色を経て銀へ戻る。
/// 端を同じ銀にしておくと、どの角度で切っても金属の連続に見える
let auroraLocations: [CGFloat] = [0.00, 0.12, 0.26, 0.40, 0.54, 0.67, 0.80, 1.00]
let auroraColors: [CGColor] = [
    rgb(0xD7DEE8), rgb(0xB9C8E8), rgb(0xCFC0EC), rgb(0xF0C6DE),
    rgb(0xF6DCC0), rgb(0xDCEBC6), rgb(0xC2E4E4), rgb(0xD7DEE8),
]

let aurora = CGGradient(colorsSpace: space,
                        colors: auroraColors as CFArray,
                        locations: auroraLocations)!

/// 金属らしさは色相だけでは出ない。斜めに白い帯を重ねて反射を作る
let sheenLocations: [CGFloat] = [0.0, 0.16, 0.30, 0.44, 0.58, 0.74, 1.0]
let sheenColors: [CGColor] = [
    rgb(0xFFFFFF, 0.0), rgb(0xFFFFFF, 0.55), rgb(0xFFFFFF, 0.0), rgb(0x8E9AAE, 0.22),
    rgb(0xFFFFFF, 0.0), rgb(0xFFFFFF, 0.38), rgb(0xFFFFFF, 0.0),
]

let sheen = CGGradient(colorsSpace: space,
                       colors: sheenColors as CFArray,
                       locations: sheenLocations)!

/// 指定角度で図形をまたぐ線分を返す
func axis(_ radians: Double, span: Double = rOuter * 1.35) -> (CGPoint, CGPoint) {
    let dir = CGPoint(x: cos(radians), y: sin(radians))
    return (CGPoint(x: center.x - dir.x * span, y: center.y - dir.y * span),
            CGPoint(x: center.x + dir.x * span, y: center.y + dir.y * span))
}

struct Style {
    let name: String
    let background: UInt32?
    let border: UInt32       // 型抜きの縁
    let backing: UInt32      // めくれて見える裏面(粘着面)
}

/// 白の縁が地から分離して見えるかどうかを、コントラスト比で確かめる。
/// 文字ではないので4.5:1は要らないが、2:1を割ると原寸で輪郭が溶ける
func contrastAgainstWhite(_ hex: UInt32) -> Double {
    func channel(_ v: UInt32) -> Double {
        let c = Double(v) / 255
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    let l = 0.2126 * channel((hex >> 16) & 0xFF)
        + 0.7152 * channel((hex >> 8) & 0xFF)
        + 0.0722 * channel(hex & 0xFF)
    return 1.05 / (l + 0.05)
}

func makeContext(opaque: Bool) -> CGContext {
    let info = opaque ? CGImageAlphaInfo.noneSkipLast : CGImageAlphaInfo.premultipliedLast
    guard let ctx = CGContext(data: nil, width: Int(size), height: Int(size),
                              bitsPerComponent: 8, bytesPerRow: Int(size) * 4,
                              space: space, bitmapInfo: info.rawValue) else {
        fatalError("コンテキストを作れない")
    }
    ctx.setAllowsAntialiasing(true)
    ctx.setMiterLimit(12)
    return ctx
}

/// 縁を描いてから中身を塗る。線は中心揃えなので、塗りで内側半分が隠れて外に縁だけ残る
func strokeBorder(_ ctx: CGContext, path: CGPath, color: UInt32) {
    ctx.addPath(path)
    ctx.setLineWidth(borderWidth)
    ctx.setLineJoin(.miter)
    ctx.setStrokeColor(rgb(color))
    ctx.strokePath()
}

func draw(into ctx: CGContext, style: Style, fit: CGAffineTransform) {
    if let background = style.background {
        ctx.setFillColor(rgb(background))
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    }

    ctx.saveGState()
    ctx.concatenate(fit)

    // 貼られている側。縁 → オーロラ → 反射の順に重ねる
    ctx.saveGState()
    ctx.addPath(adheredSide)
    ctx.clip()

    strokeBorder(ctx, path: burst, color: style.border)

    ctx.saveGState()
    ctx.addPath(burst)
    ctx.clip()
    let (a0, a1) = axis(-0.55)
    ctx.drawLinearGradient(aurora, start: a0, end: a1, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    let (s0, s1) = axis(1.05)
    ctx.drawLinearGradient(sheen, start: s0, end: s1, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()

    ctx.restoreGState()

    // 折り返った裏面。粘着面なので艶は無く、縁だけ表と揃える
    ctx.saveGState()
    ctx.addPath(adheredSide)
    ctx.clip()
    ctx.setShadow(offset: CGSize(width: -size * 0.010, height: size * 0.010),
                  blur: size * 0.026, color: rgb(0x000000, 0.30))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    strokeBorder(ctx, path: flap, color: style.border)
    ctx.addPath(flap)
    ctx.setFillColor(rgb(style.backing))
    ctx.fillPath()
    ctx.endTransparencyLayer()
    ctx.restoreGState()

    ctx.restoreGState()
}

/// 切り欠きの分だけ重心がずれるため、一度描いて背景以外の範囲を測る
func contentBounds(of ctx: CGContext, background: UInt32) -> CGRect {
    guard let data = ctx.data else { fatalError("ピクセルを読めない") }
    let buf = data.bindMemory(to: UInt8.self, capacity: Int(size * size) * 4)
    let br = Int((background >> 16) & 0xFF), bg = Int((background >> 8) & 0xFF), bb = Int(background & 0xFF)
    var minX = Int(size), minY = Int(size), maxX = -1, maxY = -1
    for y in 0..<Int(size) {
        for x in 0..<Int(size) {
            let o = (y * Int(size) + x) * 4
            // 影で滲むため完全一致ではなく許容差で背景を判定する
            if abs(Int(buf[o]) - br) < 6, abs(Int(buf[o + 1]) - bg) < 6, abs(Int(buf[o + 2]) - bb) < 6 { continue }
            if x < minX { minX = x }; if x > maxX { maxX = x }
            if y < minY { minY = y }; if y > maxY { maxY = y }
        }
    }
    return CGRect(x: Double(minX), y: Double(minY),
                  width: Double(maxX - minX + 1), height: Double(maxY - minY + 1))
}

func write(_ ctx: CGContext, to name: String) {
    guard let image = ctx.makeImage() else { fatalError("画像化に失敗") }
    guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: name) as CFURL,
                                                     UTType.png.identifier as CFString, 1, nil) else {
        fatalError("出力先を作れない")
    }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(name)")
}

/// 配置は一度だけ測り、全ての書き出しで同じものを使う。
/// 縁と影の分まで含めた実際の描画範囲を見るため、測定にも本番と同じ描画を使う
func fitTransform(targetSpan: Double) -> CGAffineTransform {
    let probe = makeContext(opaque: true)
    let probeStyle = Style(name: "probe", background: 0xF5F5F5, border: 0xFFFFFF, backing: 0xD8DBE0)
    draw(into: probe, style: probeStyle, fit: .identity)
    let bounds = contentBounds(of: probe, background: 0xF5F5F5)
    let scale = targetSpan / max(bounds.width, bounds.height)
    return CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY)
        .concatenating(CGAffineTransform(scaleX: scale, y: scale))
        .concatenating(CGAffineTransform(translationX: size / 2, y: size / 2))
}

/// 地は藤色。淡いままだと白縁との差が1.4:1しかなく原寸で輪郭が溶けるため、
/// 色味は保ったまま明度だけ落として2:1を確保している
let iconBackground: UInt32 = 0xB4AED6

// iOSがさらに角丸で切るため端まで攻めない
let iconFit = fitTransform(targetSpan: size * 0.82)
let icon = makeContext(opaque: true)
draw(into: icon, style: Style(name: "lilac", background: iconBackground, border: 0xFFFFFF, backing: 0xB6B3CA), fit: iconFit)
write(icon, to: "AppIcon-1024.png")
print(String(format: "  白縁と地のコントラスト比 %.2f:1", contrastAgainstWhite(iconBackground)))

// アプリ内で使うロゴマーク。地の上に直接置くため背景は透過にする。
// ライトモードの地(bgBase #F5F5F5)の上では白い縁が消えるため、縁だけ銀に落とす
let markFit = fitTransform(targetSpan: size * 0.94)
let marks: [(String, UInt32, UInt32)] = [("light", 0xC3C8D3, 0xB9BEC8), ("dark", 0xFFFFFF, 0xC4C9D2)]
for (suffix, border, backing) in marks {
    let ctx = makeContext(opaque: false)
    draw(into: ctx, style: Style(name: suffix, background: nil, border: border, backing: backing), fit: markFit)
    write(ctx, to: "logo_mark_\(suffix).png")
}
