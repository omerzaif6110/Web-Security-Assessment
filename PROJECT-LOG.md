# PROJECT LOG

> Yeni bir oturuma başlarken **önce bu dosyayı oku.** En üstte "Şu anki durum" ve "Bir sonraki adım" var.

## Şu anki durum
- **Aktif faz:** Faz 7 ✅ tamamlandı → **PROJE TAMAMLANDI** 🎉
- **Son güncelleme:** 2026-11-26

## Bir sonraki adım
Faz 3 — Zafiyet analizi (ZAP/Burp, 6-8 bulgu derinlemesine), çıktılar `Vulnerability-Analysis/`, `Findings/`:
1. ~~Bellek kararı~~ → artırıldı (`mem_limit 1536m`, heap 1 GB). **Ama sızıntı var:** bellek istek başına ~0,75 MB
   büyüyor; 1 GB heap ~3400 istekte (40 rps'de ~85 sn) doluyor ve uygulama yine çöküyor.
   **Karar (kullanıcı, 2026-11-25): bölerek tara.** Her tarama parçasından önce `docker restart juice-shop`
   (bellek sıfırlanır), tarama sırasında bellek ve nginx 502 sayısı izlenir; çökme olursa o parça tekrarlanır.
   Kök neden araştırması yapılmayacak (raporda "araştırılmadı" olarak belirtilir).
   Hazırlık: ZAP 2.17.0 kuruldu (kullanıcı). ✅ Parça 1 (spider + pasif) tamam → `Vulnerability-Analysis/README.md`.
   **Sıradaki:** SPA kapsamı (AJAX spider / API uç noktaları) → aktif tarama parçaları.
   ZAP yeniden başlatma: `zaproxy -Xmx1024m -daemon -host 127.0.0.1 -port 8090 -config api.key=<yeni rastgele>
   -config api.addrs.addr.name=127.0.0.1 -config api.addrs.addr.regex=false`, sonra context `juice` yeniden oluşturulmalı.
   Not: Kullanıcı sudo parolasını paylaşmayı teklif etti; Claude parola girmez — sudo adımlarını kullanıcı yapar.

### 2026-11-25 — Faz 3: API yüzeyi + 4 bulgu doğrulandı
Ayrıntı: [Vulnerability-Analysis/README.md](Vulnerability-Analysis/README.md) · bulgular `Findings/F-0X-*.md`
- API keşfi: `main.js` içinden 51 uç nokta çıkarıldı (AJAX spider yerine statik JS analizi — bellek dostu).
  ZAP ile durum haritası: 20 × 200 (kimlik doğrulamasız), 13 × 401 (korumalı), 18 × 500 (POST uç noktaları).
- **Doğrulanan bulgular:** F-01 SQLi giriş atlatma (Kritik), F-02 aramada SQLi + hata ifşası (Yüksek),
  F-03 /api/Feedbacks yetkisiz veri ifşası (Orta), F-04 /ftp KeePass dosyası (Yüksek).
- Yıkıcı test yapılmadı: parola tablosu çekilmedi, kdbx açılmadı, dosyalar diske kaydedilmedi, token maskelendi.
- **Tespit boşluğu (Faz 4):** başarılı SQLi giriş atlatması (200) Wazuh'ta hiç alarm üretmedi; nginx logu
  istek gövdesini/Authorization başlığını görmüyor.

**Faz 3 tamamlandı — 7 bulgu:** F-01 SQLi giriş (Kritik), F-02 arama SQLi (Yüksek), F-03 Feedbacks veri
ifşası (Orta), F-04 /ftp KeePass (Yüksek), F-05 açık yönlendirme (Orta), F-06 CORS (Düşük),
F-07 eksik güvenlik başlıkları (Orta). İncelenen ama ertelenen: XSS, IDOR (captcha/oturum gerektiriyor).

## Faz 4 için hazır girdiler (tespit boşlukları)
Faz 3'te ÖNEMLİ bulgu: saldırıların çoğu Wazuh'ta görünmedi çünkü nginx access log istek gövdesini,
`Authorization` başlığını ve 2xx/3xx içindeki saldırıları göstermiyor. Faz 4 kural fikirleri:
- F-01/F-02 SQLi kalıpları (gövdede) → uygulama logu entegrasyonu gerekebilir
- F-04 `/ftp` hassas uzantılara erişim (kdbx, bak) → nginx logundan yakalanabilir
- F-05 `/redirect?to=http...` dış şema → nginx logundan yakalanabilir
- Tarama/frekans: aynı IP'den yüksek istek, 502 patlaması (R-04)
ZAP daemon çalışıyor olabilir; gerekmiyorsa kapatılabilir (`pkill -f zap-2.17`).

### 2026-11-25 — Faz 4: Wazuh özel tespit kuralları
Ayrıntı: [Detection/README.md](Detection/README.md) · kurallar `Detection/rules/local_rules.xml`
- ZAP kapatıldı (bellek boşaldı). Hazır 31103 SQLi kuralı anahtar kelime aradığı için tırnak/boolean
  SQLi'yi kaçırıyordu; uygulamaya özel saldırıların hiç kuralı yoktu.
- 3 özel kural (100101 SQLi, 100110 /ftp hassas dosya, 100120 açık yönlendirme). `<url type="pcre2">`
  kullanıldı (`<field name="url">` hata veriyor); `if_sid>31100,31108` (basit GET'ler 31108'e düşüyor).
- Kurallar repodan manager'a salt okunur mount edildi (override, kalıcı). Mount yolu repo kökü için
  `../../../../` (Detection/ kökte, logs/ lab/ içinde — bir seviye fark).
- Doğrulama: wazuh-logtest birim testi (doğru pozitif + normal istekte alarm yok) VE canlı uçtan uca
  (3 saldırı → ~8 sn'de indexer'da 3 alarm). Kanıt README'de.
- Dürüst kör nokta: F-01 giriş SQLi gövdede olduğu için access log'dan yakalanamıyor; gövde loglamak
  parolaları da loglar (önerilmez). Faz 6 önleme konusu.

**Sıradaki Faz 5 — Wireshark:** Faz 3/4 saldırı trafiğini yakala ve analiz et. Lab Docker köprüsünde
(`br-...` 172.30.20.0/24 veya loopback) dinle. Çıktılar `Network-Analysis/` (ham pcap repoya girmez).
İsteğe bağlı: Faz 4 alarmlarının dashboard ekran görüntüsü (kullanıcı; `rule.id:100101 100110 100120`).

### 2026-11-25 — Faz 5: Ağ trafiği analizi (tshark)
Ayrıntı: [Network-Analysis/README.md](Network-Analysis/README.md) · metin kanıtı `Network-Analysis/extracts/`
- tshark ile yakalama (sudo'suz: dumpcap capability + wireshark grubu). `-i any`, tcp 8080+3000, 98 paket.
- Saldırılar tekrarlandı; her biri iki bacakta görüldü (Kali→nginx:8080, nginx→juice-shop:3000).
- **Ana sonuç:** giriş SQLi yükü (`{"email":"' OR 1=1--",...}`) paket gövdesinde açıkça görünüyor →
  Faz 4'teki F-01 kör noktasını (access log gövdeyi görmez) paket görünürlüğü kapatıyor.
- X-Forwarded-For=172.30.20.1 (nginx ekliyor) → Wazuh'ta tüm saldırıların tek IP'den görünmesinin nedeni.
- kdbx (3246 B octet-stream) düz metin HTTP'de telden geçti (TLS yok → hassas veri şifresiz).
- Ham pcap repoya girmez (.gitignore); kdbx baytları + JWT içerir. Yalnızca metin özetleri commit'lendi.

**Sıradaki Faz 6 — Düzeltme + yeniden test:** nginx'te hızlı kazanımlar (güvenlik başlıkları F-07,
/ftp engeli F-04, açık yönlendirme F-05, server_tokens F-? ); her düzeltmeden sonra yeniden test (önce/sonra).
SQLi (F-01/F-02) kök nedeni uygulama kodunda → nginx hafifletme + kod önerisi. KARAR: hangi bulgular düzeltilecek
(hepsi mi, öncelikli mi) kullanıcıyla konuşulacak.

### 2026-11-26 — Faz 6: Düzeltme ve yeniden test
Ayrıntı: [Remediation/README.md](Remediation/README.md) · önce/sonra `Remediation/before-after/`
- Karar (kullanıcı): nginx'te temiz düzeltmeler. nginx config sertleştirildi (`lab/nginx/default.conf`).
- Düzeltilen + yeniden test edilen: F-04 (/ftp→403), F-05 (açık yönlendirme atlatma→403, meşru redirect korundu),
  F-06 (ACAO:* kaldırıldı), F-07 (CSP+Referrer+Permissions eklendi), R-07 (server_tokens off).
- Normal işlev korundu (ana sayfa/arama 200, SPA tarayıcıda tam yüklendi — browser paneli + konsol doğrulaması).
  CSP ilk başta Google Fonts'u engelledi → meşru kaynak eklendi (iyi CSP meşru ihtiyaçlara izin verir).
- Savunma derinliği kanıtlandı: engellenen (403) saldırılar Faz 4 Wazuh kurallarını HÂLÂ tetikliyor
  (önleme + tespit birlikte).
- Düzeltilmeyen (kök neden kodda, öneri olarak belgelendi): F-01/F-02 SQLi, F-03 yetkisiz erişim.

**Sıradaki Faz 7 — SON FAZ (Rapor):** tüm fazları toplayan PDF/yönetici özeti rapor, README cilalama,
LinkedIn yazısı. Bütün ham veri ve kanıt repoda hazır. Lab çalışır durumda.
2. Faz 2 adayları: R-02 `/ftp` hassas dosyalar, R-03 ayrıntılı hatalar, R-05 CORS, R-06 PUT/DELETE,
   `/redirect` (açık yönlendirme), `/rest/*` ve `/api/*` (SQLi, IDOR, auth), + ZAP/Burp ile bulunacaklar.
3. Her bulgu `Findings/F-XX-*.md`: açıklama, adımlar, kanıt (ekran görüntüsü), etki, OWASP Top 10, Wazuh tespit
   edildi mi, düzeltme önerisi.
4. Saldırılar `127.0.0.1:8080` üzerinden (SCOPE kuralı).

Lab erişimi: Juice Shop http://127.0.0.1:8080 · Wazuh dashboard https://127.0.0.1 (varsayılan kimlik bilgileri, kabul edilmiş risk)

---

## Faz planı
| Faz | Konu | Çıktı klasörü | Durum |
|---|---|---|---|
| 0 | Planlama, iskelet, kapsam | kök dizin | Tamamlandı |
| 1 | Lab kurulumu (Docker Compose: Juice Shop + nginx + Wazuh) | `lab/` | Tamamlandı |
| 2 | Keşif (nmap) | `Reconnaissance/` | Tamamlandı |
| 3 | Zafiyet analizi (ZAP/Burp, 6-8 bulgu derinlemesine) | `Vulnerability-Analysis/`, `Findings/` | Bekliyor |
| 4 | Wazuh tespit kuralları | `Detection/` | Bekliyor |
| 5 | Wireshark trafik analizi | `Network-Analysis/` | Bekliyor |
| 6 | Düzeltme ve yeniden test | `Remediation/` | Bekliyor |
| 7 | PDF rapor, README, LinkedIn yazısı | Report/ | Tamamlandı |

## Kararlar
| Tarih | Karar | Neden |
|---|---|---|
| 2026-11-22 | Her şey tek Kali VM içinde Docker Compose ile | Tek makine, kolay sıfırlama, izole ağ |
| 2026-11-22 | Hedef: OWASP Juice Shop | Bilinen, yasal, OWASP Top 10'u kapsayan hedef |
| 2026-11-22 | Juice Shop önünde nginx reverse proxy | Gerçekçi mimari; erişim logları Wazuh'a beslenir; düzeltmeler (header, rate limit) proxy'de yapılabilir |
| 2026-11-22 | Wazuh single-node | Tek VM için yeterli; multi-node gereksiz kaynak tüketir |
| 2026-11-22 | Proje klasörü `~/Projects/Web-Security-Assessment` | Oturumdan bağımsız, kalıcı konum |
| 2026-11-22 | Ham pcap/log repoya girmez | İçlerinde oturum çerezi/parola olabilir; boyutları büyük |
| 2026-11-22 | Ekran görüntüsü adı: `YYYY-MM-DD_HHMMSS_faz<N>_<bulgu>.png` | Rapor yazarken kronolojik ve faza göre sıralanabilir |

## Oturum günlüğü

### 2026-11-22 — Faz 0 başlangıcı
**Yapılanlar**
- Ortam kontrolü: `git` 2.53.0 var. `gh` ve `scrot` **kurulu değil**. `sudo` parola istiyor, bu yüzden kurulumu kullanıcı yapacak.
  git `user.name` / `user.email` ayarlı değil.
- Klasör iskeleti oluşturuldu (boş klasörler `.gitkeep` ile git'e dahil).
- `.gitignore`, `SCOPE.md`, `PROJECT-LOG.md`, `README.md` taslağı yazıldı.
- `tools/screenshot.sh` yazıldı; sözdizimi ve hata yolları test edildi.
- Kullanıcı kurulumu yaptı: `scrot` 2.0.0 (Kali deposu). `gh` Kali deposunda **yok**; GitHub'ın resmi
  apt deposu (cli.github.com) eklenerek `gh` 2.105.0 kuruldu.
- `gh auth login`: tarayıcı otomatik açılamadı (DRI3 hatası); device flow ile
  github.com/login/device elle açılarak, 2FA (authenticator) ile giriş yapıldı. Protokol: HTTPS.
- Deneme görüntüsü alındı: `Screenshots/2026-11-22_090740_faz0_deneme.png` (1920x922 PNG).
  İçinde maskeli token öneki ve terminal içeriği görüldüğü için **repoya eklenmedi** (.gitignore).
- İlk commit atıldı, private GitHub reposu oluşturulup push edildi.

**Öğrenilenler**
- `cmd1 && cmd2` zincirinde bir komut hata verirse sonrakiler çalışmaz (gh hatası scrot kurulumunu da durdurdu).
- `git config` anahtarları `bölüm.ad` biçimindedir (`user.name`, `user.email`).
- Ekran görüntüsü commit'lenmeden önce içeriği kontrol edilmeli.

### 2026-11-22 — Faz 1 başlangıcı: ortam kontrolü
**Bulgular**
- Yalnızca `docker-cli` kurulu; **Docker motoru (`docker.io` / dockerd) yok**, Compose yok.
- `kali` kullanıcısı `docker` grubunda değil.
- 4 CPU, 8.4 GB RAM (~5 GB boş), 53 GB boş disk → yeterli; Wazuh indexer heap'i düşük tutulacak.
- `vm.max_map_count = 1048576` (Wazuh için ≥262144 gerekli) → değişiklik gerekmiyor.
- Hostta açık portlar: 127.0.0.1:9050 (Tor), 127.0.0.1:38167 → lab portlarıyla çakışma yok.
- Wazuh sürümü: resmi `wazuh/wazuh-docker` deposunun son kararlı etiketi **v4.14.10**.

**Karar (kullanıcı):** `kali` `docker` grubuna eklendi. Bu grup root eşdeğeri yetki verir
(`docker run -v /:/host`); yalnızca lab amaçlı VM olduğu için kabul edildi.

### 2026-11-22 — Faz 1: Docker kurulumu ve hedef katman
**Yapılanlar**
- Kullanıcı kurdu: `docker.io` 28.5.2, `docker-compose` 2.40.3. Kurulum sorusu "purge'da verileri sil?" → **No**
  (Wazuh volume'larındaki kanıtlar korunsun). `hello-world` çalıştı (yeniden oturum açıldıktan sonra).
- `lab/docker-compose.yml`: Juice Shop `v20.4.0` + nginx `1.30.7-alpine` (sürümler sabitlendi).
  - `wsa-lab-internal` 172.30.10.0/24 (`internal: true`): juice-shop .10, nginx .20
  - `wsa-lab-edge` 172.30.20.0/24: nginx .20, port `127.0.0.1:8080`
- nginx baseline config: güvenlik başlığı / rate limit / TLS **bilerek yok** (Faz 6'da eklenecek).

**Doğrulama testleri (gerçekten yapıldı)**
| Test | Beklenen | Sonuç |
|---|---|---|
| `curl 127.0.0.1:8080` | 200, Juice Shop | ✅ HTTP 200, `<title>OWASP Juice Shop` |
| `curl 10.0.2.3:8080` (VM'in LAN IP'si) | Bağlanamamalı | ✅ bağlanamadı; `ss`: yalnızca 127.0.0.1:8080 |
| juice-shop içinden `1.1.1.1:443` TCP | Başarısız | ✅ `ENETUNREACH` |
| nginx access.log dosyaya yazılıyor | Evet | ✅ `lab/logs/nginx/access.log` |
| Kali → `172.30.10.10:3000` doğrudan | — | ⚠️ HTTP 200: host köprü arayüzünden nginx'i atlayabiliyor → SCOPE'a kural eklendi |

**Karşılaşılan sorunlar ve çözümler**
1. Her istek access.log'a **iki kez** yazılıyordu. Neden: imajın `nginx.conf`'u http{} seviyesinde
   `access_log ... main` tanımlıyor; benim `combined` satırım da aynı seviyedeydi → ikisi birden aktif.
   Çözüm: `access_log`'u `server{}` içine taşı (alt blok üsttekini geçersiz kılar).
2. Düzeltmeden sonra da çift satır devam etti. Neden: **tek dosya bind-mount** inode'a bağlanır; dosya
   yeniden yazılınca container eski içeriği görür (`docker exec ... grep` ile doğrulandı).
   Çözüm: klasör bağlama (`./nginx:/etc/nginx/conf.d:ro`) + `--force-recreate`. Sonra 1 istek = 1 satır ✅

**Öğrenilenler**
- Linux grup üyeliği oturum açılışında okunur; `usermod -aG` sonrası yeniden giriş gerekir.
- `internal: true` ağ internete çıkışı keser ama host'un köprü IP'si üzerinden erişimi engellemez.
- Internal ağda port yayınlanamaz; bu yüzden nginx ayrıca bir "edge" ağına bağlı.
- Config'i "yükledim" demek yetmez; container'ın gerçekte ne gördüğünü kontrol et.

### 2026-11-22 — Faz 1: Wazuh single-node
**Kararlar**
- **Varsayılan parolalar değiştirilmedi** (kullanıcı kararı). Kabul edilmiş risk: dashboard yalnızca
  `127.0.0.1:443`'te; LAN'dan erişilemez. Raporda "gerçek ortamda ilk değiştirilecek ayar" olarak belirtilecek.
- Resmi `wazuh/wazuh-docker` v4.14.10 `lab/wazuh/upstream/` altına klonlandı (repoya girmez).
  Not: `git clone --branch v4.14.10` "tag is not a commit" uyarısı verdi; gelinen commit `76ddb88`
  (revert-image-tag-4.14.10-rc2 merge). Compose imajları `4.14.10` olarak sabitli.
- Resmi dosyalara dokunulmadı; değişiklikler `lab/wazuh/docker-compose.override.yml` içinde:
  - Resmi compose **6 portu 0.0.0.0'a açıyor** (1514, 1515, 514/udp, 55000, 9200, 443).
    Override: yalnızca dashboard `127.0.0.1:443`; diğerleri `!reset []` ile kaldırıldı.
  - Ağ `wsa-wazuh` **172.30.30.0/24**.
  - `lab/logs/nginx` → manager `/var/log/nginx-lab` **salt okunur** (kanıt bütünlüğü).
  - `lab/wazuh/wazuh_manager.conf` = resmi dosya + 2 `localfile` (nginx access/error, `syslog` formatı).
- `lab/wazuh/wazuh.sh`: iki compose dosyasını birleştiren sarmalayıcı.
- TLS sertifikaları resmi üretici ile oluşturuldu: 12 dosya, izinler 400, sahipler 1000/999.
  Üretici çıktısında `find: command not found` vardı (temizlik adımı); tüm sertifikalar üretildi (listelenerek doğrulandı).

**Başlatma ve doğrulama (gerçekten yapıldı)**
- İmajlar indirildi (manager 981 MB, indexer 1044 MB, dashboard 483 MB sıkıştırılmış; ~25 dk sürdü).
- `wazuh.sh up -d` → 3 konteyner `Up`. Bellek: 4.6 GB kullanılabilir.
- Host'ta dinleyen tüm portlar `127.0.0.1` üzerinde: 443 (Wazuh dashboard), 8080 (nginx), 9050 (Tor) ve iki geçici port.
  9200 / 55000 / 1514 / 1515 host'ta **yok** ✅ (override çalışıyor).
- **Henüz yapılmadı:** dashboard girişi, wazuh-logtest, nginx→Wazuh alarm testi.

### 2026-11-23 — Faz 1: Wazuh doğrulama ve uçtan uca test
**Yeniden başlatma testi:** VM kapatılıp açıldı → 5 konteyner kendiliğinden kalktı (restart politikaları çalışıyor),
portlar yine yalnızca 127.0.0.1.

**Sağlık kontrolleri (gerçekten yapıldı)**
| Bileşen | Kontrol | Sonuç |
|---|---|---|
| Manager | `wazuh-control status` | analysisd, logcollector, remoted, apid, wazuh-db çalışıyor ✅ (cluster/mail/integrator vb. single-node'da kapalı, normal) |
| Logcollector | `ossec.log` | `/var/log/nginx-lab/access.log` ve `error.log` izleniyor ✅ |
| Indexer | `_cluster/health` | `green`, 1 node, shard %100 ✅ |
| API | `POST /security/user/authenticate` | HTTP 200 ✅ |
| Dashboard | `https://127.0.0.1/` | 302 → `/app/login` ✅ |
| Filebeat → indexer | `filebeat test output` | TLSv1.2, `talk to server... OK` ✅ |

Not: Kontrollerde parolalar komuta yazılmadı; konteynerlerin kendi ortam değişkenleri kullanıldı, token yazdırılmadı.

**Decoder testi (`wazuh-logtest`, örnek satırlar)** — `syslog` log_format doğru; decoder `web-accesslog`
| Örnek satır | Kural | Seviye | Açıklama |
|---|---|---|---|
| `GET /` 200 | 31108 | 0 | Ignored URLs (alarm yok) |
| `...UNION SELECT...` 200 | 31106 | 6 | A web attack returned code 200 (success), MITRE T1190 |
| `GET /admin.php` 404 | 31101 | 5 | Web server 400 error code |

**Uçtan uca test** (2026-11-23 17:22:17 UTC, User-Agent işareti `wsa-faz1-e2e-122217`)
- İstek: `GET http://127.0.0.1:8080/wsa-e2e-test?q=1'%20UNION%20SELECT%20null--` (var olmayan yol; veritabanına dokunmaz) → HTTP 200
- nginx access.log: satır yazıldı ✅
- Wazuh `alerts.json`: **kural 31106, seviye 6**, groups `web, accesslog, attack`, MITRE T1190,
  srcip `172.30.20.1`, location `/var/log/nginx-lab/access.log`, ~1 sn içinde ✅
- Indexer: ilk sorgu (8 sn sonra, `full_log:*e2e*`) 0 sonuç; ikinci sorgu (+15 sn, `rule.id:31106`) alarmı buldu ✅
  (ilk sonucun nedeni Filebeat gecikmesi ya da joker sorgu biçimi olabilir; ayrıştırılmadı)
- Dashboard (Threat Hunting → Events, `rule.id:31106`): alarm görüldü ✅
  Kanıt: `Screenshots/2026-11-23_123811_faz1_wazuh-alarm-31106-e2e.png`
  (data.url, full_log, decoder, rule 31106/6, MITRE T1190, PCI DSS 6.5/11.4, NIST SA.11/SI.4)
- Dashboard kullanımında karşılaşılan sorun: zaman aralığı yanlışlıkla ters dönmüştü (başlangıç > bitiş) →
  "No results"; takvim → "Last 24 hours" ile çözüldü. İlk ekran görüntüsü yalnızca görev çubuğunu yakaladı
  (seçim sırasında Firefox önde değildi) → kullanılmadı, commit'lenmedi; `-d 5` gecikmeli tam ekran ile yeniden alındı.

**Faz 1 sonucu: TAMAMLANDI.** Lab çalışıyor, izole, yeniden başlatmaya dayanıklı; saldırı → tespit zinciri doğrulandı.

### 2026-11-23 — Faz 2: Keşif
Ayrıntılı rapor: [Reconnaissance/README.md](Reconnaissance/README.md) · ham çıktılar `Reconnaissance/scans/`
- Hedefler `docker network inspect` ile doğrulandı; gateway'ler (Kali'nin kendisi) ve Wazuh ağı hariç tutuldu.
- nmap: 3 host, 3 açık port (3000 Juice Shop, 2×80 nginx) + 127.0.0.1:8080. Sudo'suz SYN taraması (nmap capability).
- 10 keşif bulgusu (R-01…R-10): proxy atlama, `/ftp` dizin listeleme (kdbx, .bak), ayrıntılı hatalar, CORS `*`,
  PUT/DELETE, sürüm ifşası, eksik başlıklar…
- **Beklenmedik olay:** ffuf taramaları sırasında Juice Shop **5 kez çöktü** (V8 heap OOM, exit 139, `OOMKilled=false`);
  nginx 4916×502. ffuf'un varsayılan eşleştiricisi 502'yi göstermediği için sonuçlar eksik/tutarsızdı → iki tur + elle doğrulama.
  DoS yasak olduğu için çökme yeniden üretilmedi; yalnızca loglardan analiz.
- Yanlış pozitifler doğrulandı: nmap `http-open-proxy` (kapsam dışına trafik **çıkmadı**), port 3000 `ppp?`, http-enum sessizliği.
- Wazuh: 9895 alarm, ama port taramaları ve doğrudan 3000 erişimi **hiç** görülmedi; "web taraması" korelasyonu (31151) 0 → Faz 4.

**Öğrenilenler**
- Otomatik araç çıktısı ≠ gerçek: ham cevabı oku (nmap `ppp?` aslında HTTP'ydi).
- SPA'ların "her şeye 200" davranışı http-enum'u ve 404 tabanlı tespit kurallarını körleştiriyor.
- ffuf `-mc` varsayılanı 502'yi içermez; hedef çökerken tarama sessizce eksik sonuç verir.
- Taramanın hedefte ne yaptığını (5xx, çökme) loglardan izlemek keşfin parçası.
- `OOMKilled=false` ≠ bellek sorunu yok: Node.js'in kendi heap sınırı cgroup sınırından önce dolabilir.

### 2026-11-23 — Juice Shop bellek düzeltmesi ve kararlılık testi
- Kullanıcı kararı: belleği artır. `lab/docker-compose.yml`: `mem_limit 768m → 1536m`, `NODE_OPTIONS=--max-old-space-size=1024`.
  Heap sınırı 432 → 1120 MB (PID 1 ortamında doğrulandı). Uygulama açılışta ~5 sn 502 verdi, sonra 200.
- Kararlılık testi (Faz 2 ffuf yükünün aynısı, 40 rps, 17:58–18:01 UTC): **1 çökme** (önceden 5), 691 × 502.
  Bellek 3 sn'de ~90 MB doğrusal arttı, 1.28 GiB'ta heap OOM → **uygulama seviyesinde bellek sızıntısı**.
  Söz verildiği gibi test tekrarlanmadı/zorlanmadı. R-04 "Yüksek"e yükseltildi (Reconnaissance/README.md §5.3).
- **Öğrenilen:** Kaynak artırmak sızıntıyı çözmez, yalnızca geciktirir; ölçmeden "düzeldi" denmez.

**Gözlem (Faz 4 için):** Kaynak IP her zaman `172.30.20.1` (edge ağının gateway'i = Kali). nginx'in arkasında
gerçek istemci IP'si korunuyor ama Wazuh'ta tüm saldırılar aynı IP'den görünecek. Wazuh kuralı 31106 kalıp + HTTP 200
birleşimine bakıyor; var olmayan bir yola atılan istek de SPA fallback yüzünden 200 döndüğü için "başarılı saldırı"
olarak etiketlendi → **yanlış pozitif örneği**, Faz 4'te ele alınacak.

**Öğrenilenler**
- Compose override'da relative yollar ilk compose dosyasının klasörüne göre çözülür.
- Compose'da listeyi birleştirmek yerine değiştirmek için `!override`, boşaltmak için `!reset` etiketi kullanılır.

### 2026-11-26 — Faz 7: Raporlama (SON FAZ) ✅
- Report/report.html → Report/report.pdf (weasyprint): kapak, yönetici özeti, 7 bulgu, tespit,
  düzeltme, sonuç. Yazar adı yer tutucu (kullanıcı doldurur); e-posta rapora konmadı.
- README.md portföy için cilalandı: mimari, bulgu tablosu, yetkinlikler, metodoloji ilkeleri.
- Report/linkedin-post.md: kısa + uzun iki sürüm taslağı.
- **7 fazın tamamı bitti. Proje tamamlandı.**

## Proje tamamlandı — olası ileri adımlar (isteğe bağlı)
- Yazar adını rapora ekle, repoyu public yap (önce commit geçmişinde e-posta vb. gözden geçir).
- TLS/HSTS ekle; SQLi için kod düzeyinde düzeltme + yeniden test (şu an nginx dışı).
- Bellek sızıntısı (R-04) kök neden analizi. XSS/IDOR derinleştirme turu.
- Faz 4 alarmlarının dashboard ekran görüntüleri (rapora görsel).
