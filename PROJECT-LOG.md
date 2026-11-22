# PROJECT LOG

> Yeni bir oturuma başlarken **önce bu dosyayı oku.** En üstte "Şu anki durum" ve "Bir sonraki adım" var.

## Şu anki durum
- **Aktif faz:** Faz 0 — Planlama ✅ tamamlandı
- **Son güncelleme:** 2026-11-22

## Bir sonraki adım
Faz 1 — Lab kurulumu:
1. Docker / Docker Compose kurulu mu kontrol et; VM kaynaklarını (RAM/disk) kontrol et (Wazuh single-node ~4 GB RAM ister).
2. `lab/docker-compose.yml`: Juice Shop + nginx reverse proxy + Wazuh single-node, izole bridge ağ, portlar yalnızca `127.0.0.1`.
3. nginx access/error loglarını Wazuh'a besle.
4. Lab alt ağını SCOPE.md'ye yaz.

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
