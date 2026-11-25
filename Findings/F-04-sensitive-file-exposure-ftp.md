# F-04 — Hassas Dosya İfşası (`/ftp` — KeePass veritabanı ve yedekler)

| | |
|---|---|
| **Önem** | Yüksek |
| **OWASP Top 10 (2021)** | A01:2021 — Broken Access Control / A05:2021 — Security Misconfiguration |
| **CWE** | CWE-548 (Dizin Listeleme), CWE-200 (Bilgi İfşası) |
| **Konum** | `GET /ftp/` ve altındaki dosyalar |
| **Durum** | ✅ Doğrulandı (elle + ZAP spider) · 2026-11-25 (ilk gözlem Faz 2, R-02) |

## Açıklama
`/ftp` dizini listelenebiliyor ve içindeki bazı dosyalar kimlik doğrulaması olmadan indirilebiliyor.
Dizin, **`incident-support.kdbx`** adlı bir **KeePass parola veritabanı** ve çeşitli yedek/veri
dosyaları içeriyor. Sunucu bazı uzantılarda (`.bak`, `.pyc`, `.yml`, `.gg`) **403** döndürüyor,
yani bir uzantı filtresi var ama `.kdbx`, `.md` gibi uzantılar engellenmiyor.

## Yeniden üretme
```
curl http://127.0.0.1:8080/ftp/                        # HTTP 200, dizin listesi
curl -o incident-support.kdbx \
     http://127.0.0.1:8080/ftp/incident-support.kdbx   # HTTP 200, 3246 bayt
```

## Kanıt
- Dizin listesi (`robots.txt` → `Disallow: /ftp` ile işaret ediliyordu).
- **200 (indirilebilir, kimlik doğrulamasız):** `incident-support.kdbx` (3246 B, KeePass DB),
  `announcement_encrypted.md` (369 KB), `acquisitions.md`, `legal.md`, `quarantine/*.url`.
- **403 (uzantı filtresi):** `coupons_2013.md.bak`, `package.json.bak`, `package-lock.json.bak`,
  `encrypt.pyc`, `suspicious_errors.yml`, `eastere.gg`.
- Dosyalar yalnızca tarayıcı/ZAP oturumunda erişildi; **diske kalıcı kaydedilmedi, KeePass veritabanı
  açılmaya/kırılmaya çalışılmadı** (yalnızca erişilebilirliği kanıtlandı).

## Etki
- Hassas iş dosyaları ve bir parola veritabanı herkese açık. KeePass dosyası çevrimdışı parola
  kırma denemesine (ana parola zayıfsa) maruz. Yedek dosyaları kaynak kod/sır sızıntısı riski taşır.
- Uzantı kara listesi eksik: yeni uzantılar (`.kdbx`) filtreyi atlıyor — kara liste yaklaşımının zayıflığı.

## Wazuh'ta tespit
⚠️ **Kısmen.** `.bak` gibi 403'ler ve bazı istekler "Suspicious URL access" (31516) tetikledi,
ama `.kdbx` indirmesi (200) alarm üretmedi. → Faz 4: `/ftp` altındaki hassas uzantılara erişim kuralı.

## Düzeltme
- `/ftp` dizin listelemesini kapat; dosyalara erişimi kaldır ya da kimlik doğrulaması arkasına al.
- Kara liste yerine **beyaz liste** (yalnızca izin verilen uzantılar/dosyalar sunulsun).
- Parola veritabanı, yedekler ve sırlar web kök dizininde hiç bulunmamalı.
