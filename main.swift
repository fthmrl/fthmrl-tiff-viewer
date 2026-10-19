import AppKit
import ImageIO

// TIFF Viewer: TIFF'i Önizleme'de açar. Önizleme'nin açamadığı eski JPEG sıkıştırmalı
// TIFF'lerde sayfaları geçici bir PDF'e koyup onu açar; asıl dosyaya dokunmaz.

func u16(_ d: Data, _ o: Int, _ le: Bool) -> Int {
    let a = Int(d[o]), b = Int(d[o + 1]); return le ? a | b << 8 : a << 8 | b
}
func u32(_ d: Data, _ o: Int, _ le: Bool) -> Int {
    le ? u16(d, o, le) | u16(d, o + 2, le) << 16 : u16(d, o, le) << 16 | u16(d, o + 2, le)
}

/// Her sayfa için ImageIO ile çözülebilen görüntüyü, olmazsa gömülü JPEG'i döndürür.
func pages(_ url: URL) -> [CGImage] {
    guard let d = try? Data(contentsOf: url), d.count > 8 else { return [] }
    let src = CGImageSourceCreateWithData(d as CFData, nil)
    let le = d[0] == 0x49
    var out: [CGImage] = []
    var off = u32(d, 4, le), i = 0
    while off > 0 && off + 2 < d.count && i < 2000 {
        let n = u16(d, off, le)
        var tags: [Int: Int] = [:]
        for k in 0..<n {
            let e = off + 2 + k * 12
            guard e + 12 <= d.count else { break }
            tags[u16(d, e, le)] = u32(d, e + 8, le)
        }
        var img: CGImage? = nil
        if tags[259] != 6, let s = src { img = CGImageSourceCreateImageAtIndex(s, i, nil) }
        if img == nil, let s = tags[513], let l = tags[514], s + l <= d.count,
           let js = CGImageSourceCreateWithData(d.subdata(in: s..<s + l) as CFData, nil) {
            img = CGImageSourceCreateImageAtIndex(js, 0, nil)
        }
        if img == nil, let s = src { img = CGImageSourceCreateImageAtIndex(s, i, nil) }
        if let img { out.append(img) }
        let next = off + 2 + n * 12
        off = next + 4 <= d.count ? u32(d, next, le) : 0
        i += 1
    }
    return out
}

func needsHelp(_ url: URL) -> Bool {
    guard let s = CGImageSourceCreateWithURL(url as CFURL, nil) else { return true }
    let n = CGImageSourceGetCount(s)
    if n == 0 { return true }
    for i in 0..<n where CGImageSourceCreateImageAtIndex(s, i, nil) == nil { return true }
    // Eski JPEG (sıkıştırma 6) ImageIO'da bozuk/boş çıkabiliyor; her durumda yardımla aç.
    if let p = CGImageSourceCopyPropertiesAtIndex(s, 0, nil) as? [CFString: Any],
       let t = p[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
       (t[kCGImagePropertyTIFFCompression] as? Int) == 6 { return true }
    return false
}

func makePDF(_ url: URL) -> URL? {
    let imgs = pages(url)
    if imgs.isEmpty { return nil }
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("TIFF Viewer/\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let pdf = dir.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".pdf")
    guard let ctx = CGContext(pdf as CFURL, mediaBox: nil, nil) else { return nil }
    for img in imgs {
        let w = CGFloat(img.width), h = CGFloat(img.height)
        let scale: CGFloat = w > 1500 ? 72.0 / 300.0 : 72.0 / 150.0  // taramalar çoğunlukla 300 dpi
        var box = CGRect(x: 0, y: 0, width: w * scale, height: h * scale)
        ctx.beginPage(mediaBox: &box)
        ctx.draw(img, in: box)
        ctx.endPage()
    }
    ctx.closePDF()
    return pdf
}

let preview = URL(fileURLWithPath: "/System/Applications/Preview.app")

// MARK: Sürüm, güncelleme ve yenilikler

let SURUM = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1") ?? 1
let KLASOR_ADI = "FTHMRL TIFF VIEWER"

/// Her sürümün yenilikleri; güncellemeden sonraki ilk açılışta bir kez gösterilir.
let YENILIKLER: [Int: [String]] = [
    2: ["Yeni sürüm çıkınca açılışta haber verir ve tek tıkla günceller.",
        "Her güncellemeden sonra yenilikleri bir kez gösterir."],
    3: ["Güncellemeler artık GitHub'dan da gelir; programı paylaştığınız meslektaşlarınız da yeni sürümleri alır.",
        "Belgeleriniz bilgisayarınızdan hiçbir yere gönderilmez; internete yalnızca yeni sürüm var mı diye bakılır."],
    4: ["Uygulamanın adı artık TIFF Viewer."],
    5: ["Yeni simge: siyah-beyaz, 8-bit piksel tarzı."],
]

let GITHUB_DEPO = "fthmrl/tiff-viewer"
let UYGULAMA_ADI = "TIFF Viewer"
let ESKI_ADLAR = ["fthmrl tiff viewer.app", "TIFF Okuyucu.app"]

/// Uygulamanın diskteki yeri; eski adla kuruluysa adiDuzelt() yeni yeri yazar.
var uygulamaYolu = Bundle.main.bundleURL

/// v3 ve öncesinden güncellenen kurulumlarda uygulama dosyasının adını "TIFF Viewer.app" yapar.
func adiDuzelt() {
    let fm = FileManager.default
    guard ESKI_ADLAR.contains(uygulamaYolu.lastPathComponent) else { return }
    let yeni = uygulamaYolu.deletingLastPathComponent().appendingPathComponent(UYGULAMA_ADI + ".app")
    guard !fm.fileExists(atPath: yeni.path), (try? fm.moveItem(at: uygulamaYolu, to: yeni)) != nil else { return }
    uygulamaYolu = yeni
    _ = calistir("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", ["-f", yeni.path])
}

struct SurumBilgisi: Decodable { let surum: Int; let dosya: String; let notlar: [String]? }

/// OneDrive'daki AI/FTHMRL TIFF VIEWER klasörü (hesap adı her Mac'te farklı olabilir).
func yayimKlasoru() -> URL? {
    let fm = FileManager.default
    let cs = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/CloudStorage")
    let hesaplar = (try? fm.contentsOfDirectory(at: cs, includingPropertiesForKeys: nil)) ?? []
    for h in hesaplar where h.lastPathComponent.hasPrefix("OneDrive") {
        for ai in ["AI", "Aİ"] {
            let k = h.appendingPathComponent(ai).appendingPathComponent(KLASOR_ADI)
            if fm.fileExists(atPath: k.appendingPathComponent("surum.json").path) { return k }
        }
    }
    return nil
}

func uyari(_ baslik: String, _ metin: String, _ dugmeler: [String] = ["Tamam"]) -> Int {
    let a = NSAlert()
    a.messageText = baslik
    a.informativeText = metin
    a.icon = NSApp.applicationIconImage
    for d in dugmeler { a.addButton(withTitle: d) }
    NSApp.activate(ignoringOtherApps: true)
    return a.runModal().rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
}

func calistir(_ yol: String, _ arg: [String]) -> Bool {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: yol)
    p.arguments = arg
    do { try p.run(); p.waitUntilExit() } catch { return false }
    return p.terminationStatus == 0
}

/// İnternetten tek bir küçük dosya okur (yalnızca GET; hiçbir veri gönderilmez).
func indir(_ url: URL, zamanAsimi: TimeInterval) -> Data? {
    var sonuc: Data?
    let s = DispatchSemaphore(value: 0)
    var istek = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: zamanAsimi)
    istek.httpMethod = "GET"
    URLSession.shared.dataTask(with: istek) { d, r, _ in
        if (r as? HTTPURLResponse)?.statusCode == 200 { sonuc = d }
        s.signal()
    }.resume()
    s.wait()
    return sonuc
}

/// En yeni sürüm: önce GitHub'daki son yayın, sonra (varsa) OneDrive klasörü; hangisi büyükse.
func enYeniSurum() -> (SurumBilgisi, URL)? {
    var adaylar: [(SurumBilgisi, URL)] = []
    let gh = URL(string: "https://github.com/\(GITHUB_DEPO)/releases/latest/download/")!
    if let d = indir(gh.appendingPathComponent("surum.json"), zamanAsimi: 4),
       let b = try? JSONDecoder().decode(SurumBilgisi.self, from: d) {
        adaylar.append((b, URL(string: "https://github.com/\(GITHUB_DEPO)/releases/download/v\(b.surum)/\(b.dosya)")!))
    }
    if let k = yayimKlasoru(),
       let d = try? Data(contentsOf: k.appendingPathComponent("surum.json")),
       let b = try? JSONDecoder().decode(SurumBilgisi.self, from: d),
       FileManager.default.fileExists(atPath: k.appendingPathComponent(b.dosya).path) {
        adaylar.append((b, k.appendingPathComponent(b.dosya)))
    }
    return adaylar.filter { $0.0.surum > SURUM }.max { $0.0.surum < $1.0.surum }
}

/// Yeni sürüm varsa sorar; kabul edilirse kurar, yeni sürümü aynı dosyalarla açar ve true döner.
func guncellemeVarsaSor(_ urls: [URL]) -> Bool {
    guard let (b, kaynak) = enYeniSurum() else { return false }
    var metin = "TIFF Viewer v\(b.surum) yayımlandı (yüklü olan: v\(SURUM))."
    if let n = b.notlar, !n.isEmpty { metin += "\n\n" + n.map { "• " + $0 }.joined(separator: "\n") }
    metin += "\n\nYeni sürüm yüklensin mi?"
    if uyari("Yeni sürüm var", metin, ["Yükle", "Sonra"]) != 0 { return false }

    let fm = FileManager.default
    let gecici = fm.temporaryDirectory.appendingPathComponent("tiffviewer-guncelleme-\(UUID().uuidString)")
    try? fm.createDirectory(at: gecici, withIntermediateDirectories: true)
    var zip = kaynak
    if !kaynak.isFileURL {
        zip = gecici.appendingPathComponent(b.dosya)
        guard let d = indir(kaynak, zamanAsimi: 120), (try? d.write(to: zip)) != nil else {
            _ = uyari("Güncelleme indirilemedi", "İnternet bağlantınızı kontrol edin. Belge şimdilik bu sürümle açılacak.")
            return false
        }
    }
    let acilan = gecici.appendingPathComponent("acilan")
    let hedef = uygulamaYolu
    guard calistir("/usr/bin/ditto", ["-x", "-k", zip.path, acilan.path]),
          let yeni = (try? fm.contentsOfDirectory(at: acilan, includingPropertiesForKeys: nil))?
              .first(where: { $0.pathExtension == "app" }),
          (try? fm.replaceItemAt(hedef, withItemAt: yeni)) != nil else {
        _ = uyari("Güncelleme yüklenemedi", "Belge şimdilik bu sürümle açılacak.")
        return false
    }
    _ = calistir("/usr/bin/xattr", ["-dr", "com.apple.quarantine", hedef.path])
    let cfg = NSWorkspace.OpenConfiguration()
    cfg.createsNewApplicationInstance = true
    let bitir: (NSRunningApplication?, Error?) -> Void = { _, _ in DispatchQueue.main.async { NSApp.terminate(nil) } }
    if urls.isEmpty { NSWorkspace.shared.openApplication(at: hedef, configuration: cfg, completionHandler: bitir) }
    else { NSWorkspace.shared.open(urls, withApplicationAt: hedef, configuration: cfg, completionHandler: bitir) }
    return true
}

/// Bu sürümün yeniliklerini daha önce gösterilmediyse bir kez gösterir.
func yenilikleriGoster() {
    let ud = UserDefaults.standard
    guard ud.integer(forKey: "gorulenSurum") < SURUM else { return }
    ud.set(SURUM, forKey: "gorulenSurum")
    guard let n = YENILIKLER[SURUM] else { return }
    _ = uyari("Yenilikler — v\(SURUM)", n.map { "• " + $0 }.joined(separator: "\n"))
}

/// Açılışta önce güncelleme, sonra yenilikler; true ise bu örnek kapanacak.
func acilisKontrolleri(_ urls: [URL]) -> Bool {
    adiDuzelt()
    if guncellemeVarsaSor(urls) { return true }
    yenilikleriGoster()
    return false
}

func show(_ urls: [URL]) {
    var targets: [URL] = []
    var failed: [String] = []
    for u in urls {
        if !needsHelp(u) { targets.append(u) }
        else if let p = makePDF(u) { targets.append(p) }
        else { failed.append(u.lastPathComponent) }
    }
    if !failed.isEmpty { _ = uyari("Açılamadı", failed.joined(separator: "\n")) }
    if targets.isEmpty { NSApp.terminate(nil); return }
    NSWorkspace.shared.open(targets, withApplicationAt: preview, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
        DispatchQueue.main.async { NSApp.terminate(nil) }
    }
}

class Delegate: NSObject, NSApplicationDelegate {
    var opened = false
    func application(_ app: NSApplication, open urls: [URL]) {
        opened = true
        if acilisKontrolleri(urls) { return }
        show(urls)
    }
    func applicationDidFinishLaunching(_ n: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.opened { return }
            if acilisKontrolleri([]) { return }
            let p = NSOpenPanel()
            p.allowsMultipleSelection = true
            p.allowedContentTypes = [.tiff]
            NSApp.activate(ignoringOtherApps: true)
            if p.runModal() == .OK { show(p.urls) } else { NSApp.terminate(nil) }
        }
    }
}

let app = NSApplication.shared
let delegate = Delegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
