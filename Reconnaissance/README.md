# Faz 2 — Keşif (Reconnaissance)

**Tarih:** 2026-11-23 · **Kaynak:** Kali (aynı VM) · **Araçlar:** nmap 7.99, curl, ffuf 2.1.0-dev
**Kapsam:** [targets.md](targets.md) — 172.30.10.0/24, 172.30.20.0/24 (gateway'ler hariç), 127.0.0.1:8080
**Ham çıktılar:** [scans/](scans/) · zaman damgaları: [scans/scan-times.txt](scans/scan-times.txt)

> Bu belgede yalnızca gerçekten çalıştırılan komutlar ve gözlenen sonuçlar yer alır.
> Faz 2 yalnızca keşiftir: hiçbir zafiyet istismar edilmedi, `/ftp` altındaki dosyalar indirilmedi.

---

## 1. Metodoloji ve komutlar

| # | Adım | Komut | Çıktı |
|---|---|---|---|
| 0 | Hedef doğrulama | `docker network inspect wsa-lab-internal wsa-lab-edge wsa-wazuh` | [targets.md](targets.md) |
| 1 | Host keşfi | `nmap --privileged -sn -n --reason 172.30.10.0/24 172.30.20.0/24 --exclude 172.30.10.1,172.30.20.1` | `scans/01-host-discovery.*` |
| 2 | Tüm TCP portları | `nmap --privileged -sS -p- -n --reason -T4 172.30.10.10 172.30.10.20 172.30.20.20` | `scans/02-tcp-allports.*` |
| 3 | Servis/sürüm + varsayılan scriptler | `nmap -sS -sV -sC -p 3000 172.30.10.10` · `-p 80 172.30.10.20 172.30.20.20` · `-sT -sV -sC -p 8080 127.0.0.1` | `scans/03{a,b,c}-*` |
| 4 | HTTP başlıkları (baseline) | `curl -sI http://127.0.0.1:8080/` | `scans/04a-headers-baseline.txt` |
| 5 | HTTP metodları, http-enum | `nmap -sT -p 8080 --script http-methods,http-enum --script-args http-methods.test-all=true 127.0.0.1` | `scans/05-http-scripts-8080.*` |
| 6 | İçerik keşfi (2 tur) | `ffuf -u http://127.0.0.1:8080/FUZZ -w dirb/common.txt -fs 9984 -t 10 -rate 100` ve `-t 5 -rate 40` | `scans/06-ffuf-common.json`, `scans/06b-ffuf-common-rate40.json` |
| 7 | Tespit analizi | Wazuh indexer sorgusu (17:41–17:50 UTC, rule.id'ye göre) + nginx error.log | §5 |

**Neden `--privileged` ve sudo yok:** Kali, `/usr/lib/nmap/nmap`'e `cap_net_raw,cap_net_admin` verir; root olmadan
SYN taraması (`-sS`) ve ARP keşfi yapılabilir. `127.0.0.1` için `-sT` kullanıldı (loopback'te SYN gerekmez).

**Neden iki aşamalı port taraması:** önce `-p-` ile hızlıca açık portlar (5 sn), sonra yalnızca açık portlarda
`-sV -sC` — 65535 portta sürüm tespiti gereksiz yavaş ve gürültülü olurdu.

---

## 2. Envanter

| Host | MAC | Port | Servis (doğrulanmış) | Not |
|---|---|---|---|---|
| 172.30.10.10 | 76:1C:EE:F2:11:AF | 3000/tcp | Juice Shop (Node.js/Express) | nmap: `ppp?` — tanıyamadı (bkz. §4) |
| 172.30.10.20 | 22:8E:08:8B:64:67 | 80/tcp | nginx 1.30.7 → Juice Shop | iç ağ bacağı |
| 172.30.20.20 | DE:6A:E5:0F:65:EC | 80/tcp | nginx 1.30.7 → Juice Shop | edge bacağı |
| 127.0.0.1 | — | 8080/tcp | nginx 1.30.7 (host yayını) | tek resmi giriş noktası |

- Tüm hostlar `received arp-response`, TTL 64 (Linux).
- MAC üreticileri "Unknown": Docker **yerel yönetimli** MAC üretir (ilk baytın 2. biti = 1) → sanal/konteyner ipucu.

---

## 3. Bulgular (keşif seviyesinde)

Önem dereceleri ön değerlendirmedir; "Faz 3" işaretliler orada derinlemesine doğrulanacak.

| ID | Bulgu | Kanıt | Ön derece | Sonraki adım |
|---|---|---|---|---|
| R-01 | **Reverse proxy atlanabiliyor**: Juice Shop'a `172.30.10.10:3000` üzerinden doğrudan erişim | `02-tcp-allports`, `03a` | Orta | Bu yol nginx loglarına/Wazuh'a düşmüyor. Gerçek ortamda uygulama yalnızca proxy'den erişilebilir olmalı |
| R-02 | **`/ftp` dizin listeleme** — `incident-support.kdbx` (KeePass), `*.bak` yedekler, `encrypt.pyc`, `suspicious_errors.yml`, `quarantine/` | `curl /ftp/` (yalnızca adlar) | Yüksek (aday) | Faz 3: hassas veri ifşası |
| R-03 | **Ayrıntılı hata sayfaları**: `/api`, `/rest/*` → 500; `Express ^4.22.1` ve iç yollar (`/juice-shop/node_modules/express/lib/router/...`) | `curl /api` | Düşük | Faz 3: stack trace içeriği |
| R-04 | **Erişilebilirlik / bellek sızıntısı**: ~40–100 istek/sn'lik içerik keşfi uygulamayı **5 kez çökertti** (V8 heap OOM). Bellek istek başına ~0,75 MB büyüyor ve geri verilmiyor; 1 GB heap ile de ~3400 istekte çöküyor. nginx'te rate limiting yok | §5.2, §5.3 | Yüksek | Faz 6: `limit_req` (yalnızca hafifletir; kök neden uygulamada) |
| R-05 | **Gevşek CORS**: `Access-Control-Allow-Origin: *`, izinli metodlar `GET,HEAD,PUT,PATCH,POST,DELETE` | `03*` http-cors, `04a` | Orta (aday) | Faz 3 |
| R-06 | **Riskli HTTP metodları** ilan ediliyor: `PUT`, `DELETE` | `05-http-scripts-8080` | Düşük (aday) | Faz 3: gerçekten işlevsel mi? |
| R-07 | **Sürüm ifşası**: `Server: nginx/1.30.7` | `04a` | Bilgi | Faz 6: `server_tokens off` |
| R-08 | **Eksik güvenlik başlıkları**: Content-Security-Policy, Referrer-Policy, Permissions-Policy (yalnızca eski `Feature-Policy` var). `X-Content-Type-Options` ve `X-Frame-Options` **uygulama** tarafından ekleniyor, nginx değil | `04a` | Düşük | Faz 6 (önce/sonra karşılaştırması bu dosyaya göre) |
| R-09 | `robots.txt` → `Disallow: /ftp` (hassas yolu işaret ediyor) | `03*` http-robots.txt | Bilgi | R-02 ile bağlantılı |
| R-10 | Özel başlık `X-Recruiting: /#/jobs` | `04a` | Bilgi | — |

**Faz 3 için diğer ipuçları:** `/redirect` (500 — açık yönlendirme adayı), `/promotion` (200), `/profile` (500, oturum gerekebilir), `/rest/*` ve `/api/*` API yüzeyi.

---

## 4. Yanlış pozitifler ve araç sınırları

| Gözlem | Gerçek | Nasıl doğrulandı |
|---|---|---|
| nmap `http-open-proxy`: "Proxy might be redirecting requests" (8080) | **Yanlış pozitif.** nginx açık proxy değil; her isteği sabit `proxy_pass` ile Juice Shop'a gönderiyor | nginx logunda `GET http://www.google.com` vb. hepsi 9984 bayt (= Juice Shop ana sayfası); `curl --proxy 127.0.0.1:8080 http://example.com` → `<title>OWASP Juice Shop`; juice-shop'tan dışarı TCP → `ENETUNREACH`. **Kapsam dışına trafik çıkmadı.** |
| nmap port 3000 → `ppp?` | HTTP (Express). `Server` ve `X-Powered-By` başlıkları olmadığı için `-sV` imza eşleştiremedi | fingerprint-strings içinde `HTTP/1.1 200 OK` ve `<title>OWASP Juice Shop` |
| nmap `http-enum`: sonuç yok (yalnızca 13 istek) | Juice Shop bilinmeyen yollara **200** (SPA fallback) döndüğü için script 404'ü ayırt edemeyip erken bıraktı | `curl /bu-yol-yok-xyz` → 200, 9984 bayt |
| ffuf: `/cgi-bin2`, `/layout` → 200, **0 bayt** | Uygulama o an çöküyordu; yarıda kalan cevap | Tekrar: 3/3 → 200, 9984 bayt; nginx error.log: "upstream prematurely closed" |
| ffuf: `/restaurants`, `/restore`, `/restricted`… → 500 | Gerçek yol değil; `/rest` ile **başlayan** her yol API router'ına düşüp "Unexpected path" hatası veriyor | — |
| ffuf tur 1 `/ftp`, `robots.txt`'yi **kaçırdı**; tur 2 `/media`'yı kaçırdı | Uygulama çökükken nginx **502** döndü; ffuf'un varsayılan `-mc` listesinde **502 yok** → sessizce yok sayıldı | Küçük listeyle tekrar: üçü de bulundu. İki turun birleşimi + elle doğrulama kullanıldı |

**Metodoloji dersi:** "Her şeye 200 dönen" bir uygulama (SPA) üç farklı aracı yanılttı; tek bir otomatik tarama
eksik ve tekrarlanamaz sonuç verebilir. Birden çok turun birleşimi alınmalı, önemli bulgular elle doğrulanmalı,
taramanın hedefte ne yaptığı (çökme, 5xx) loglardan izlenmeli.

---

## 5. Mavi takım görünümü (Wazuh)

### 5.1 Tarama aralığındaki alarmlar (17:41–17:50 UTC)
Toplam **9895** alarm:

| Kural | Adet | Sev. | Açıklama | Gerçekte |
|---|---|---|---|---|
| 31301 | 4953 | 3 | Nginx error message | Upstream'e bağlanamama (uygulama çökük) |
| 31120 | 4914 | 5 | Web server 500 error code | Çoğu **502** (Wazuh 5xx'i "500" diye etiketliyor) |
| 31122 | 17 | 5 | 500 (Internal Error) | `/api`, `/rest*` hata sayfaları |
| 31101 | 9 | 5 | Web server 400 error code | nmap `-sC`/http-methods (400/405), open-proxy denemeleri |
| 31104 | 1 | 6 | Common web attack (T1190) | ffuf: `/msadc` |
| 31516 | 1 | 6 | Suspicious URL access | ffuf: `/server-status` |

### 5.2 Uygulamanın çökmesi (R-04 kanıtı)
- nginx access.log 17:43–17:49: **4916 × 502**, 4322 × 200.
- nginx error.log: 4886 × `connect() failed (111: Connection refused) while connecting to upstream`,
  29 × `upstream prematurely closed connection`, 34 × `Connection reset by peer`.
- `docker events`: `die 139` → `start` 5 kez (17:44:44, 17:45:23, 17:47:20, 17:48:01, 17:48:43); `RestartCount=5`.
- `docker inspect`: `OOMKilled=false` (cgroup sınırına takılmadı).
- `docker logs juice-shop`: `FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory`,
  heap ~380 MB'ta → Node, 768 MB konteyner sınırına göre heap sınırını ~yarısı olarak seçmiş.
- Çökme anında işlenen istekler rastgele kelimeler (`/public`, `/ldap`, `/slides`…) → tek bir tetikleyici istek yok,
  **birikmiş yük** (~40 sn'de bir). SCOPE gereği (DoS yasak) çökme yeniden üretilmeye çalışılmadı; analiz yalnızca mevcut loglardan.

### 5.3 Takip testi: bellek artırımı ve sızıntı (2026-11-23 17:58–18:01 UTC)
Lab düzeltmesi: `mem_limit 768m → 1536m`, `NODE_OPTIONS=--max-old-space-size=1024` (heap sınırı 432 → 1120 MB,
PID 1'in ortamında doğrulandı). Aynı yük (ffuf, `dirb/common.txt`, 40 istek/sn) tekrarlandı:

- 3 sn aralıklı bellek örnekleri: `181 → 270 → 365 → 445 → 540 → 610 → 672 → 747 → 790 → 884 → 1014 MiB → 1.04 → 1.10 → 1.18 → 1.25 → 1.28 GiB`
  → **çökme** (18:00:11, exit 139, `JavaScript heap out of memory`, heap 1019.8 MB) → yeniden başlama → `42 → … → 716 MiB`.
- Sonuç: 1 çökme (önceki ayarda 5), 691 × 502.
- **Bellek istek sayısıyla doğrusal büyüyor ve GC ile geri kazanılmıyor** (~90 MB / 3 sn ≈ istek başına ~0,75 MB)
  → uygulama seviyesinde **bellek sızıntısı**. Heap'i büyütmek çökmeyi yalnızca geciktiriyor (432 MB: ~40 sn, 1 GB: ~85 sn).
- **R-04 güncellemesi:** Kimlik doğrulaması gerektirmeyen ~3–4 bin sıradan GET isteği uygulamayı çökertebiliyor.
  Sızıntının kök nedeni araştırılmadı (Juice Shop kaynak kodu analizi gerektirir).

### 5.4 Tespit boşlukları (Faz 4 girdisi)
| Saldırgan eylemi | Görüldü mü | Neden |
|---|---|---|
| ARP keşfi, SYN port taramaları | ❌ | Wazuh yalnızca nginx loglarını okuyor; ağ sensörü yok |
| `172.30.10.10:3000`'e doğrudan erişim | ❌ | nginx'i atlıyor (R-01) |
| nmap `-sV -sC` | ⚠️ zayıf (31101 ×9) | Tekil 400/405 alarmları, korelasyon yok |
| ffuf ~9.000 istek | ⚠️ yalnızca 2 imza (31104, 31516) | Çoğu istek 200 döndü |
| "Web taraması" korelasyonu (31151: aynı kaynaktan çok sayıda 400) | ❌ 0 | SPA 404 yerine 200 döndürüyor → kural hiç tetiklenmiyor |
| Uygulama çökmesi | ⚠️ dolaylı | Binlerce 5xx/nginx error alarmı var ama "servis düştü" anlamında tek bir alarm yok |

**Faz 4 kural fikirleri:** aynı kaynaktan kısa sürede yüksek istek sayısı (frekans), 502 patlaması = erişilebilirlik
alarmı, `/ftp` ve hassas uzantılara (`.kdbx`, `.bak`) erişim, bilinen tarayıcı User-Agent'ları.
