#!/usr/bin/env bash
# Emülatöre, önceden tanımlı kapalı bir yürüyüş döngüsü (polygon) boyunca GPS
# konumları gönderir. Treadom'da "Koşmaya Başla"ya bastıktan sonra çalıştır;
# rota çizilir, döngü kapanınca alan (polygon) oluşur ve kaydedilir.
#
# Asıl amaç: FETHETME senaryosunu denemek. Rotalar bir ızgara üzerine
# yerleştirildi; bazıları yan yana (kenar paylaşır), bazıları üst üste biner
# veya keser. Örnek akış:
#   1) Bir kullanıcıyla giriş yap, rota 1'i koş -> "Merkez Kare" alanını al.
#   2) Başka bir kullanıcıyla giriş yap, rota 5'i ("Büyük Kuşatma") koş ->
#      rota 1'in alanını içine aldığı için onu FETHEDER.
#
# Kullanım:
#   tool/simulate_walk.sh [rota_no]        # rota_no: 1..6 (varsayılan 1)
#
# Ortam değişkenleriyle ince ayar (opsiyonel):
#   BASE_LAT, BASE_LON  ızgaranın sol-alt köşesinin merkezi (varsayılan Ankara)
#   UNIT                ızgara birimi, derece (~100 m, varsayılan 0.0009)
#   STEPS               iki köşe arası ara nokta sayısı (varsayılan 6)
#   DELAY               noktalar arası bekleme, sn (varsayılan 1.0)
#   ADB                 adb yolu (varsayılan ~/Android/Sdk/platform-tools/adb)
#
# Örnek: daha hızlı simülasyon
#   STEPS=4 DELAY=0.5 tool/simulate_walk.sh 5
set -euo pipefail

ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"

ROUTE="${1:-1}"
BASE_LAT="${BASE_LAT:-39.9208}"   # ızgara orijini enlem (Ankara yakını)
BASE_LON="${BASE_LON:-32.8541}"   # ızgara orijini boylam
UNIT="${UNIT:-0.0009}"            # bir ızgara birimi, derece (~100 m)
STEPS="${STEPS:-6}"               # köşeler arası interpolasyon adımı
DELAY="${DELAY:-1.0}"             # noktalar arası bekleme (sn)

# Rotalar ızgara koordinatlarıyla (gx,gy) tanımlı kapalı döngülerdir; son nokta
# başlangıca eşittir (döngü kapanır). Konumlar bilinçli seçildi:
#   1 ve 2 -> yan yana (x=1 kenarını paylaşır)
#   3      -> 1'in kuzey komşusu (y=1 kenarını paylaşır)
#   4      -> 1,2,3'ün ortasına oturur, hepsiyle kısmen çakışır
#   5      -> 1 ve 2'yi tamamen içine alır (ikisini birden FETHEDER)
#   6      -> dikey uzun şerit; 1 ve 3'ü dikine keser
case "$ROUTE" in
  1) NAME="Merkez Kare";   WP="0,0 1,0 1,1 0,1 0,0" ;;
  2) NAME="Dogu Komsu";    WP="1,0 2,0 2,1 1,1 1,0" ;;
  3) NAME="Kuzey Komsu";   WP="0,1 1,1 1,2 0,2 0,1" ;;
  4) NAME="Capraz Fetih";  WP="0.5,0.5 1.5,0.5 1.5,1.5 0.5,1.5 0.5,0.5" ;;
  5) NAME="Buyuk Kusatma"; WP="-0.3,-0.4 2.3,-0.4 2.3,1.4 -0.3,1.4 -0.3,-0.4" ;;
  6) NAME="Uzun Serit";    WP="0.2,-0.3 0.8,-0.3 0.8,2.3 0.2,2.3 0.2,-0.3" ;;
  *) echo "Geçersiz rota: '$ROUTE'. 1..6 arası bir değer ver." >&2; exit 1 ;;
esac

if [[ ! -x "$ADB" ]] && ! command -v "$ADB" >/dev/null 2>&1; then
  echo "adb bulunamadı: $ADB" >&2
  echo "ADB ortam değişkeniyle yol verebilirsin: ADB=/yol/adb $0 $ROUTE" >&2
  exit 1
fi

# Bağlı (çalışan) bir emülatör var mı? 'emulator-...' satırı ararız.
if ! "$ADB" devices | grep -q "emulator-"; then
  echo "Çalışan bir emülatör görünmüyor. Önce emülatörü başlat." >&2
  "$ADB" devices >&2
  exit 1
fi

# (gx, gy) ızgara noktasını (enlem, boylam) çiftine çevirir. Boylam, çember/kare
# ekranda gerçekçi (kare) görünsün diye enleme göre cos ile düzeltilir.
grid_to_latlon() {
  awk -v gx="$1" -v gy="$2" -v blat="$BASE_LAT" -v blon="$BASE_LON" -v u="$UNIT" 'BEGIN{
    pi = 3.14159265358979;
    lat = blat + gy * u;
    lon = blon + gx * (u / cos(blat * pi / 180));
    printf "%.6f %.6f\n", lat, lon;
  }'
}

# Köşe ızgara noktalarını gerçek enlem/boylama çevirip dizilere yaz.
read -r -a CELLS <<< "$WP"
LATS=(); LONS=()
for cell in "${CELLS[@]}"; do
  gx="${cell%,*}"; gy="${cell#*,}"
  read -r plat plon < <(grid_to_latlon "$gx" "$gy")
  LATS+=("$plat"); LONS+=("$plon")
done

N="${#LATS[@]}"
echo "Rota $ROUTE — \"$NAME\": $((N-1)) köşe, köşe başına $STEPS adım, $DELAY sn aralık."
echo "Emülatöre konum gönderiliyor (Ctrl+C ile durdurabilirsin)..."

# Başlangıç noktasını bir kez gönder (avatar oraya otursun).
"$ADB" emu geo fix "${LONS[0]}" "${LATS[0]}" >/dev/null
printf "  başlangıç  (%s, %s)\n" "${LATS[0]}" "${LONS[0]}"
sleep "$DELAY"

# Her kenarı STEPS ara noktaya bölerek yürü.
for ((k=1; k<N; k++)); do
  a=$((k-1))
  for ((s=1; s<=STEPS; s++)); do
    read -r plat plon < <(awk -v la="${LATS[$a]}" -v lo="${LONS[$a]}" \
                              -v lb="${LATS[$k]}" -v ob="${LONS[$k]}" \
                              -v s="$s" -v steps="$STEPS" 'BEGIN{
      t = s / steps;
      printf "%.6f %.6f\n", la + (lb - la) * t, lo + (ob - lo) * t;
    }')
    # geo fix: önce BOYLAM, sonra ENLEM ister.
    "$ADB" emu geo fix "$plon" "$plat" >/dev/null
    printf "  kenar %d/%d  adım %d/%d  (%s, %s)\n" "$k" "$((N-1))" "$s" "$STEPS" "$plat" "$plon"
    sleep "$DELAY"
  done
done

echo "Bitti. Uygulamada 'Turu Bitir'e basabilirsin (döngü kapandı, alan oluştu)."
