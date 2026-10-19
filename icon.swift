import AppKit
let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
// Yuvarlatılmış kare zemin (koyu lacivert degrade)
let bg = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
ctx.saveGState()
let sh = NSShadow(); sh.shadowColor = NSColor.black.withAlphaComponent(0.35); sh.shadowBlurRadius = 24; sh.shadowOffset = NSSize(width: 0, height: -10); sh.set()
NSColor(calibratedRed: 0.13, green: 0.30, blue: 0.62, alpha: 1).setFill(); bg.fill()
ctx.restoreGState()
NSGradient(starting: NSColor(calibratedRed: 0.22, green: 0.47, blue: 0.86, alpha: 1), ending: NSColor(calibratedRed: 0.10, green: 0.25, blue: 0.55, alpha: 1))!.draw(in: bg, angle: -90)
// Belge sayfası
let page = NSBezierPath(roundedRect: NSRect(x: 255, y: 190, width: 440, height: 600), xRadius: 30, yRadius: 30)
NSColor.white.setFill(); page.fill()
// Satırlar
NSColor(calibratedWhite: 0.80, alpha: 1).setFill()
for i in 0..<5 { NSBezierPath(roundedRect: NSRect(x: 305, y: 260 + CGFloat(i) * 52, width: i % 2 == 0 ? 340 : 270, height: 20), xRadius: 10, yRadius: 10).fill() }
// TIFF yazısı
let p = NSMutableParagraphStyle(); p.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 150, weight: .heavy), .foregroundColor: NSColor(calibratedRed: 0.12, green: 0.30, blue: 0.64, alpha: 1), .paragraphStyle: p, .kern: 4]
("TIFF" as NSString).draw(in: NSRect(x: 255, y: 560, width: 440, height: 190), withAttributes: attrs)
// Büyüteç
let cx: CGFloat = 640, cy: CGFloat = 360, r: CGFloat = 145
ctx.saveGState()
let sh2 = NSShadow(); sh2.shadowColor = NSColor.black.withAlphaComponent(0.4); sh2.shadowBlurRadius = 18; sh2.shadowOffset = NSSize(width: 0, height: -8); sh2.set()
let handle = NSBezierPath(); handle.move(to: NSPoint(x: cx + r * 0.95, y: cy - r * 0.95)); handle.line(to: NSPoint(x: cx + r * 1.5, y: cy - r * 1.5))
handle.lineWidth = 70; handle.lineCapStyle = .round
NSColor(calibratedRed: 0.95, green: 0.62, blue: 0.15, alpha: 1).setStroke(); handle.stroke()
let lens = NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
NSColor(calibratedRed: 0.85, green: 0.93, blue: 1, alpha: 0.55).setFill(); lens.fill()
lens.lineWidth = 42; NSColor(calibratedWhite: 0.18, alpha: 1).setStroke(); lens.stroke()
ctx.restoreGState()
// Mercek parıltısı
let glare = NSBezierPath(); glare.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: r * 0.68, startAngle: 110, endAngle: 160)
glare.lineWidth = 22; glare.lineCapStyle = .round; NSColor.white.withAlphaComponent(0.85).setStroke(); glare.stroke()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "icon1024.png"))
