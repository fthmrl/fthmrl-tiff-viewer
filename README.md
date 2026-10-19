<p align="center"><img src="simge.png" width="128" alt="TIFF Viewer simgesi"></p>

<h1 align="center">TIFF Viewer</h1>

<p align="center"><b>Avukatlar için macOS'te UYAP/EBYS TIFF belgelerini açan, ücretsiz ve açık kaynak okuyucu.</b></p>

---

## Neden?

UYAP ve EBYS'den indirilen tutanak, ifade ve yazıların önemli bir kısmı **eski tip JPEG sıkıştırmalı TIFF** olarak geliyor. Mac'in kendi programları (Önizleme, Hızlı Bakış, Fotoğraflar) bu eski türü desteklemediği için belge ya hiç açılmıyor ya da boş görünüyor.

**TIFF Viewer**, meslektaşlarımın Mac'te bu belgelerle uğraşmadan, rahatça çalışabilmesi için yazıldı: TIFF'e çift tıklarsınız, belge Mac'in alışık olduğunuz **Önizleme** uygulamasında açılır. Hepsi bu.

## Özellikler

- **Eski tip TIFF'leri açar** — UYAP/EBYS taramaları dahil, Önizleme'nin açamadığı dosyaları okur.
- **Çok sayfalı belgeler** — bütün sayfalar sırasıyla; siyah-beyaz ve renkli sayfalar bir arada.
- **macOS ile tam uyumlu** — belge Önizleme'de açılır; yakınlaştırma, arama, yazdırma, işaretleme gibi tüm Önizleme özellikleri kullanılabilir.
- **Sade** — kendi penceresi yok, Dock'ta yer kaplamaz; belgeyi Önizleme'ye verir ve kapanır.
- **Asıl dosyaya dokunmaz** — yalnızca okur; belgenin yanına PDF ya da başka dosya kaydetmez.
- **Normal TIFF'lerde araya girmez** — Önizleme'nin zaten açabildiği dosyaları doğrudan ona verir.
- **Kendiliğinden güncellenir** — yeni sürüm çıkınca açılışta sorar, "Yükle" derseniz kendini günceller; yenilikleri bir kez gösterir.

## Gizlilik ve güvenlik

- **Açık kaynaktır.** Programın bütün kodu bu sayfadadır; herkes inceleyebilir.
- **Belgeleriniz bilgisayarınızdan çıkmaz.** Dosyalar yalnızca kullandığınız Mac'te okunur; hiçbir belge, içerik ya da kişisel bilgi başka bir yere gönderilmez.
- **İnternete tek bir amaçla bağlanır:** açılışta bu sayfadaki son sürüm numarasını okumak. Bu sırada hiçbir veri gönderilmez; internet yoksa program normal şekilde çalışır.
- Kayıt, hesap, reklam, kullanım istatistiği yoktur.

## Kurulum

> Gereksinim: **Apple Silicon (M1, M2, M3, M4…) işlemcili Mac**, macOS 12 veya üzeri.

Üç yoldan birini seçin. Kutuların sağ üstündeki kopyala düğmesiyle tek tıkla kopyalayabilirsiniz.

### 1. Terminal ile (en hızlısı)

**Terminal** uygulamasını açın (Spotlight'ta "Terminal" yazın), aşağıdaki satırı yapıştırıp Enter'a basın:

```bash
curl -fsSL https://github.com/fthmrl/tiff-viewer/releases/latest/download/TiffViewer.zip -o /tmp/TiffViewer.zip && ditto -x -k /tmp/TiffViewer.zip /Applications && xattr -dr com.apple.quarantine "/Applications/TIFF Viewer.app" && echo "TIFF Viewer kuruldu."
```

Bu satır son sürümü indirir, **Programlar** klasörüne koyar ve macOS'in "geliştirici doğrulanamadı" uyarısını baştan kaldırır.

### 2. Claude ile

Mac'inizde [Claude](https://claude.ai/download) (Claude Code) varsa, aşağıdaki metni kopyalayıp Claude'a yapıştırın; kurulumu ve varsayılan uygulama ayarını o yapar:

```text
GitHub'daki fthmrl/tiff-viewer uygulamasını bu Mac'e kur: https://github.com/fthmrl/tiff-viewer/releases/latest/download/TiffViewer.zip dosyasını indir, /Applications klasörüne aç, "TIFF Viewer.app" üzerindeki karantina işaretini kaldır ve TIFF (public.tiff) dosyaları için varsayılan uygulama olarak ayarla.
```

### 3. Elle

1. Sağdaki **Releases** bölümünden son sürümün `TiffViewer-vN.zip` dosyasını indirin.
2. Zip'e çift tıklayın, çıkan **TIFF Viewer** uygulamasını **Programlar** klasörüne sürükleyin.
3. İlk açılışta macOS "geliştiricisi doğrulanamadı" uyarısı verir (program App Store'dan gelmediği için). Uyarıyı kapatın, **Sistem Ayarları → Gizlilik ve Güvenlik**'te en altta **Yine de Aç**'a basın. Bu yalnızca bir kez gerekir.

### Varsayılan uygulama yapın

Terminal ya da elle kurduysanız, TIFF'lerin hep bununla açılması için: herhangi bir `.tif` dosyasına sağ tıklayın → **Bilgi Al** → **Birlikte Aç**: *TIFF Viewer* → **Tümünü Değiştir**.

Artık TIFF'e çift tıklamanız yeterli. Sonraki sürümler kendiliğinden gelir.

## Bilinen sınırlar

- Boşluk tuşuyla açılan **Hızlı Bakış**'ta eski tip TIFF'ler hâlâ görünmez; belgeyi çift tıklayarak açın.
- Intel işlemcili Mac'ler desteklenmiyor.

## Nasıl çalışır?

Eski tip TIFF'lerde her sayfa aslında sıradan bir JPEG resmidir. Program bu resimleri dosyanın içinden çıkarır, sistemin geçici klasöründe Önizleme'nin okuyabileceği bir kopya hazırlar ve onu açar. Kaynak kod: [`main.swift`](main.swift).

Kendiniz derlemek isterseniz (Xcode Komut Satırı Araçları yeterli):

```bash
swiftc -O main.swift -o tiffokuyucu
```

## Görüş, öneri ve hata bildirimi

Programın gelişmesine katkınız çok değerli. Bir isteğiniz, öneriniz ya da karşılaştığınız bir sorun varsa:

👉 **[Öneri / istek gönderin ya da hata bildirin](https://github.com/fthmrl/tiff-viewer/issues/new/choose)**

Gönderilenleri **[Issues](https://github.com/fthmrl/tiff-viewer/issues)** sekmesinde görebilir, başkalarının isteklerine 👍 ile destek verebilirsiniz. Bildirim göndermek için ücretsiz bir GitHub hesabı gerekir.

> ⚠️ Bu sayfa herkese açıktır; lütfen müvekkil belgesi, dosya numarası ya da kişisel bilgi paylaşmayın.

## Lisans

MIT — özgürce kullanabilir, paylaşabilir ve değiştirebilirsiniz. Ayrıntılar [`LICENSE`](LICENSE) dosyasında.

---

<p align="center">Av. Fatih MERAL · Meral Avukatlık Bürosu</p>
