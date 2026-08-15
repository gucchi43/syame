// ペリペリのアイコンとロゴマークを生成する。
//
// 図形は「セールマーク状のトゲトゲしたシールが8割貼られ、右下の2割がめくれて折り返っている」形。
// 名前の由来である「ペリペリ剥がす」を、文字を使わずに形だけで示している。
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

func rgb(_ hex: UInt32, alpha: Double = 1) -> CGColor {
    CGColor(srgbRed: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255, alpha: alpha)
}

func makeContext(opaque: Bool) -> CGContext {
    let info = opaque ? CGImageAlphaInfo.noneSkipLast : CGImageAlphaInfo.premultipliedLast
    guard let ctx = CGContext(data: nil, width: Int(size), height: Int(size),
                              bitsPerComponent: 8, bytesPerRow: Int(size) * 4,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: info.rawValue) else {
        fatalError("コンテキストを作れない")
    }
    ctx.setAllowsAntialiasing(true)
    return ctx
}

/// 背景を敷くかどうかだけを変えて同じ図形を描く
func draw(into ctx: CGContext, background: UInt32?, face: UInt32, back: UInt32, fit: CGAffineTransform) {
    if let background = background {
        ctx.setFillColor(rgb(background))
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    }

    ctx.saveGState()
    ctx.concatenate(fit)

    // 貼られている側の本体
    ctx.saveGState()
    ctx.addPath(adheredSide)
    ctx.clip()
    ctx.addPath(burst)
    ctx.setFillColor(rgb(face))
    ctx.fillPath()
    ctx.restoreGState()

    // 折り返った裏面。本体の上に落ちる影で浮きを出す
    ctx.saveGState()
    ctx.addPath(adheredSide)
    ctx.clip()
    ctx.setShadow(offset: CGSize(width: -size * 0.010, height: size * 0.010),
                  blur: size * 0.026,
                  color: rgb(0x000000, alpha: 0.30))
    ctx.addPath(flap)
    ctx.setFillColor(rgb(back))
    ctx.fillPath()
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
    let url = URL(fileURLWithPath: name)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("出力先を作れない")
    }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(name)")
}

/// 配置は一度だけ測り、全ての書き出しで同じものを使う
func fitTransform(targetSpan: Double) -> CGAffineTransform {
    let probe = makeContext(opaque: true)
    draw(into: probe, background: 0xF5F5F5, face: 0x191919, back: 0xB4B4B4, fit: .identity)
    let bounds = contentBounds(of: probe, background: 0xF5F5F5)
    let scale = targetSpan / max(bounds.width, bounds.height)
    return CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY)
        .concatenating(CGAffineTransform(scaleX: scale, y: scale))
        .concatenating(CGAffineTransform(translationX: size / 2, y: size / 2))
}

// 配色。peri-peri はアフリカ由来の唐辛子なので、赤は名前の意味そのもの。
// めくれた裏面を淡いピンクにすると、29ptまで縮めても2色が分離して読める
let faceLight: UInt32 = 0xE8322A, backLight: UInt32 = 0xFFC9C4
let faceDark: UInt32 = 0xF04A42, backDark: UInt32 = 0xFFD9D5
let iconBackground: UInt32 = 0xF5F5F5

// アプリアイコン。iOSがさらに角丸で切るため端まで攻めない。
// App Store はアルファ付きを受け付けないので背景を敷く
let iconFit = fitTransform(targetSpan: size * 0.82)
let icon = makeContext(opaque: true)
draw(into: icon, background: iconBackground, face: faceLight, back: backLight, fit: iconFit)
write(icon, to: "AppIcon-1024.png")

// アプリ内で使うロゴマーク。地の上に直接置くため背景は透過にする。
// 二色構成でテンプレート画像にできないため、ライトとダークを別々に書き出す
let markFit = fitTransform(targetSpan: size * 0.94)
let markLight = makeContext(opaque: false)
draw(into: markLight, background: nil, face: faceLight, back: backLight, fit: markFit)
write(markLight, to: "logo_mark_light.png")

let markDark = makeContext(opaque: false)
draw(into: markDark, background: nil, face: faceDark, back: backDark, fit: markFit)
write(markDark, to: "logo_mark_dark.png")
