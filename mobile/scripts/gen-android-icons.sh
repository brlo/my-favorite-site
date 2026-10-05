#!/bin/sh
# Иконки и заставка Android из resources/icon.png (нужен ImageMagick).
# Запуск через контейнер сайта: docker exec -w /app/mobile bibleox sh scripts/gen-android-icons.sh
set -e
SRC=resources/icon.png
BG='#F6F4E5'
RES=android/app/src/main/res

for pair in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  d=${pair%%:*}; s=${pair##*:}
  convert "$SRC" -resize ${s}x${s} "$RES/mipmap-$d/ic_launcher.png"
  convert "$SRC" -resize ${s}x${s} \( +clone -threshold -1 -negate -fill white -draw "circle $((s/2)),$((s/2)) $((s/2)),0" \) -alpha off -compose copy_opacity -composite "$RES/mipmap-$d/ic_launcher_round.png"
  # адаптивная иконка: 108dp, рисунок в безопасной зоне
  f=$((s * 108 / 48)); inner=$((f * 70 / 108))
  convert -size ${f}x${f} xc:"$BG" \( "$SRC" -resize ${inner}x${inner} \) -gravity center -composite "$RES/mipmap-$d/ic_launcher_foreground.png"
done

cat > "$RES/values/ic_launcher_background.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">$BG</color>
</resources>
XML

# заставка: логотип по центру на фоне
for f in $(find "$RES" -name splash.png); do
  size=$(identify -format '%wx%h' "$f")
  w=${size%x*}; h=${size#*x}
  m=$(( (w < h ? w : h) * 40 / 100 ))
  convert -size "$size" xc:"$BG" \( "$SRC" -resize ${m}x${m} \) -gravity center -composite "$f"
done
echo done
