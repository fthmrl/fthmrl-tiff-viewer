#!/bin/zsh
# Yeni sürüm yayımlar:  ./yayimla.sh <sürüm no> "madde 1" "madde 2" ...
# Önce main.swift içindeki YENILIKLER'e aynı sürümün maddelerini, SÜRÜM NOTLARI.txt'ye notu ekleyin.
# Zip + surum.json OneDrive klasörüne ve GitHub'a (fthmrl/tiff-viewer) yayımlanır, bu Mac'e kurulur.
set -e
N=$1; shift
K=${0:A:h}; R=${K:h}; A="TIFF Viewer.app"; Z="TiffViewer-v$N.zip"
GH=~/.local/bin/gh; DEPO=fthmrl/tiff-viewer; GIT=~/Projects/tiff-viewer
T=$(mktemp -d); B=$T/yapi; mkdir -p "$B/$A/Contents/MacOS" "$B/$A/Contents/Resources"
cp "$K/main.swift" "$T/main.swift"   # OneDrive derleme sırasında dosyaya dokunabiliyor
swiftc -O "$T/main.swift" -target arm64-apple-macos12 -o "$B/$A/Contents/MacOS/tiffokuyucu"
cp "$K/Info.plist" "$B/$A/Contents/Info.plist"
cp "$K/AppIcon.icns" "$B/$A/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $N" -c "Set :CFBundleShortVersionString $N" "$B/$A/Contents/Info.plist"
codesign --force -s - "$B/$A"
ditto -c -k --keepParent "$B/$A" "$T/$Z"
cp "$T/$Z" "$T/TiffViewer.zip"   # sabit ad: README'deki tek satırlık kurulum hep son sürümü indirir
python3 -c 'import json,sys; n=int(sys.argv[1]); print(json.dumps({"surum":n,"dosya":f"TiffViewer-v{n}.zip","notlar":sys.argv[2:]},ensure_ascii=False,indent=1))' "$N" "$@" > "$T/surum.json"

# GitHub: kaynak kodu gönder, sürümü zip + surum.json ile yayımla
if [[ ! -d $GIT/.git ]]; then
  mkdir -p $GIT; git -C $GIT init -q -b main
  git -C $GIT remote add origin https://github.com/$DEPO.git
fi
for f in main.swift icon.swift Info.plist AppIcon.icns simge.png README.md LICENSE yayimla.sh; do cp "$K/$f" $GIT/; done
cp -R "$K/.github" $GIT/
git -C $GIT add -A
git -C $GIT -c user.name=fthmrl -c user.email=fthmrl@users.noreply.github.com commit -q -m "v$N" || true
git -C $GIT -c credential.helper= -c credential.helper="!$GH auth git-credential" push -q -u origin main
NOTLAR=$(for m in "$@"; do echo "- $m"; done)
$GH release create "v$N" "$T/$Z" "$T/TiffViewer.zip" "$T/surum.json" -R $DEPO --title "v$N" --target main \
  --notes "$NOTLAR"$'\n\n'"**Kurulum:** \`$Z\` dosyasını indirin, açın ve uygulamayı Programlar'a sürükleyin. Ayrıntılar README'de."

# OneDrive: surum.json en son yazılır, zip tamamlanmadan hiçbir Mac güncellemeyi görmesin
cp "$T/$Z" "$R/$Z"; cp "$T/surum.json" "$R/surum.json"
rm -rf "/Applications/$A" "/Applications/fthmrl tiff viewer.app"; cp -R "$B/$A" /Applications/
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/$A"
echo "v$N yayımlandı (OneDrive + GitHub) ve kuruldu."
