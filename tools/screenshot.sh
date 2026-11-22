#!/usr/bin/env bash
# ------------------------------------------------------------------
# screenshot.sh — Kanıt ekran görüntüsü alır ve standart şekilde adlandırır.
#
# Ad biçimi: YYYY-MM-DD_HHMMSS_faz<N>_<bulgu>.png   (Screenshots/ altına)
#
# Kullanım:
#   tools/screenshot.sh [-s] [-d SANIYE] <faz> <bulgu>
#     -s          Alan/pencere seç (fareyle çiz ya da pencereye tıkla)
#     -d SANIYE   Çekmeden önce bekle (menüyü açmak vb. için)
#
# Örnekler:
#   tools/screenshot.sh 2 nmap-servis-taramasi
#   tools/screenshot.sh -s 3 "SQLi login bypass"
#   tools/screenshot.sh -d 5 4 wazuh-alarm-sqli
# ------------------------------------------------------------------
set -euo pipefail

usage() { sed -n '5,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

# Script nereden çağrılırsa çağrılsın Screenshots/ proje kökünde olsun
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$PROJECT_ROOT/Screenshots"

SELECT=0
DELAY=0
while getopts ":sd:h" opt; do
  case "$opt" in
    s) SELECT=1 ;;
    d) [[ "$OPTARG" =~ ^[0-9]+$ ]] || { echo "Hata: -d sayı olmalı" >&2; exit 1; }; DELAY="$OPTARG" ;;
    h|*) usage ;;
  esac
done
shift $((OPTIND - 1))

[[ $# -eq 2 ]] || usage
PHASE="$1"
FINDING="$2"

[[ "$PHASE" =~ ^[0-7]$ ]] || { echo "Hata: faz 0-7 arası bir sayı olmalı (verilen: $PHASE)" >&2; exit 1; }
command -v scrot >/dev/null || { echo "Hata: scrot kurulu değil → sudo apt install -y scrot" >&2; exit 1; }
[[ -n "${DISPLAY:-}" ]] || { echo "Hata: DISPLAY yok (grafik oturum gerekli)" >&2; exit 1; }

# Bulgu adını dosya adına uygun hale getir: Türkçe karakterleri çevir,
# küçük harf yap, harf/rakam dışını '-' yap, baştaki/sondaki '-'leri sil.
SLUG="$(printf '%s' "$FINDING" \
  | sed 'y/çğıöşüÇĞİÖŞÜ/cgiosuCGIOSU/' \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
[[ -n "$SLUG" ]] || { echo "Hata: bulgu adı boş kaldı" >&2; exit 1; }

mkdir -p "$OUT_DIR"
BASE="$(date +%Y-%m-%d_%H%M%S)_faz${PHASE}_${SLUG}"
FILE="$OUT_DIR/$BASE.png"
# Aynı saniyede ikinci görüntü alınırsa üzerine yazma
n=2; while [[ -e "$FILE" ]]; do FILE="$OUT_DIR/${BASE}_$n.png"; n=$((n + 1)); done

ARGS=(--overwrite)   # FILE zaten benzersiz; scrot'un kendi _000 ekini engeller
(( DELAY > 0 )) && ARGS+=(--delay "$DELAY")
(( SELECT == 1 )) && ARGS+=(--select)

scrot "${ARGS[@]}" "$FILE"
echo "Kaydedildi: ${FILE#"$PROJECT_ROOT"/}"
echo "Hatırlatma: görüntüde parola/token/çerez varsa rapora koymadan önce maskele."
