# PROJECT LOG

> Yeni bir oturuma başlarken **önce bu dosyayı oku.** En üstte "Şu anki durum" ve "Bir sonraki adım" var.

## Şu anki durum
- **Aktif faz:** Faz 1 ✅ tamamlandı → sıradaki Faz 2 (Keşif)
- **Son güncelleme:** 2026-11-23

## Bir sonraki adım
Faz 2 — Keşif (nmap), çıktılar `Reconnaissance/`:
1. Lab ayakta mı: `docker ps` (VM açılışında kendiliğinden kalkıyor; kalkmadıysa
   `cd lab && docker compose up -d` ve `lab/wazuh/wazuh.sh up -d`).
2. Taramadan önce hedef doğrulama: `docker network inspect` ile alt ağlar (SCOPE.md §4).
3. Yalnızca kapsam içi hedefler: `127.0.0.1` (yayınlanan portlar) ve `172.30.10.0/24`, `172.30.20.0/24`.
   Wazuh ağı (172.30.30.0/24) gözlemci; tarama hedefi değil.
4. Beklenen keşif bulgusu: Juice Shop'a nginx'i atlayan doğrudan erişim (`172.30.10.10:3000`).
5. nmap taramasının Wazuh'ta ne ürettiğine bak (nginx üzerinden geçen istekler alarm üretmeli).

Lab erişimi: Juice Shop http://127.0.0.1:8080 · Wazuh dashboard https://127.0.0.1 (varsayılan kimlik bilgileri, kabul edilmiş risk)

---

## Faz planı
| Faz | Konu | Çıktı klasörü | Durum |
|---|---|---|---|
| 0 | Planlama, iskelet, kapsam | kök dizin | Tamamlandı |
| 1 | Lab kurulumu (Docker Compose: Juice Shop + nginx + Wazuh) | `lab/` | Tamamlandı |
| 2 | Keşif (nmap) | `Reconnaissance/` | Bekliyor |
| 3 | Zafiyet analizi (ZAP/Burp, 6-8 bulgu derinlemesine) | `Vulnerability-Analysis/`, `Findings/` | Bekliyor |
| 4 | Wazuh tespit kuralları | `Detection/` | Bekliyor |
| 5 | Wireshark trafik analizi | `Network-Analysis/` | Bekliyor |
| 6 | Düzeltme ve yeniden test | `Remediation/` | Bekliyor |
| 7 | PDF rapor, README, LinkedIn yazısı | kök dizin | Bekliyor |

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

**Gözlem (Faz 4 için):** Kaynak IP her zaman `172.30.20.1` (edge ağının gateway'i = Kali). nginx'in arkasında
gerçek istemci IP'si korunuyor ama Wazuh'ta tüm saldırılar aynı IP'den görünecek. Wazuh kuralı 31106 kalıp + HTTP 200
birleşimine bakıyor; var olmayan bir yola atılan istek de SPA fallback yüzünden 200 döndüğü için "başarılı saldırı"
olarak etiketlendi → **yanlış pozitif örneği**, Faz 4'te ele alınacak.

**Öğrenilenler**
- Compose override'da relative yollar ilk compose dosyasının klasörüne göre çözülür.
- Compose'da listeyi birleştirmek yerine değiştirmek için `!override`, boşaltmak için `!reset` etiketi kullanılır.
