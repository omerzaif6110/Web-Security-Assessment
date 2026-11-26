#!/usr/bin/env bash
# ------------------------------------------------------------------
# build.sh — report.html dosyasından report.pdf üretir.
#
# Kullanım:
#   cd ~/Projects/Web-Security-Assessment/Report
#   ./build.sh
#
# Düzenleme akışı:
#   1) report.html'i bir metin editöründe aç (aşağıya bak)
#   2) metni/başlıkları değiştir, kaydet
#   3) ./build.sh çalıştır → report.pdf güncellenir
#   4) PDF'i aç: xdg-open report.pdf
# ------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")"

command -v weasyprint >/dev/null || { echo "weasyprint kurulu değil: sudo apt install -y weasyprint" >&2; exit 1; }
[[ -f report.html ]] || { echo "report.html bulunamadı (Report/ klasöründe olmalısın)" >&2; exit 1; }

echo "report.html → report.pdf üretiliyor…"
weasyprint report.html report.pdf
echo "Bitti: $(du -h report.pdf | cut -f1)  →  $(pwd)/report.pdf"
echo "Açmak için: xdg-open report.pdf"
