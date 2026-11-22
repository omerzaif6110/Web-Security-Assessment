# PROJECT LOG

> Yeni bir oturuma başlarken **önce bu dosyayı oku.** En üstte "Şu anki durum" ve "Bir sonraki adım" var.

## Şu anki durum
- **Aktif faz:** Faz 1 — Lab kurulumu (başladı)
- **Son güncelleme:** 2026-11-22

## Bir sonraki adım
Faz 1 — Lab kurulumu:
1. ~~Docker kurulumu~~ ✅
2. ~~Juice Shop + nginx (`lab/docker-compose.yml`)~~ ✅ — `cd lab && docker compose up -d`
3. **Wazuh single-node v4.14.10** kurulacak. Önce karar: varsayılan parolalar değiştirilsin mi?
   (Öneri: değiştir; parolayı kullanıcı terminalde girer, dosyalar .gitignore'da.)
4. nginx `lab/logs/nginx/access.log` → Wazuh manager'a localfile olarak bağlanacak, test alarmı üretilecek.
5. Wazuh ağını SCOPE.md'ye ekle.

---

## Faz planı
| Faz | Konu | Çıktı klasörü | Durum |
|---|---|---|---|
| 0 | Planlama, iskelet, kapsam | kök dizin | Tamamlandı |
| 1 | Lab kurulumu (Docker Compose: Juice Shop + nginx + Wazuh) | `lab/` (oluşturulacak) | Bekliyor |
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
