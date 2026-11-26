# 🛡️ Web Güvenliği Değerlendirmesi — OWASP Juice Shop Lab

Tek bir Kali Linux VM içinde, Docker Compose ile kurulan **izole bir laboratuvarda** uçtan uca web
güvenliği değerlendirmesi: **saldırı → tespit → trafik analizi → düzeltme → yeniden test → rapor.**
Hem kırmızı takım (saldırı) hem mavi takım (tespit/savunma) bakış açısını birleştirir.

> 📄 **Tam rapor:** [Report/report.pdf](Report/report.pdf) · 🧪 Hedef: OWASP Juice Shop (kasıtlı zafiyetli, yasal eğitim uygulaması)

---

## Mimari
```
 Kali (saldırgan: nmap · ZAP · Wireshark)
        │  http://127.0.0.1:8080
        ▼
 ┌──────────────── izole Docker ağı ────────────────┐
 │  nginx (ters vekil) ───────────► Juice Shop       │
 │        │ access/error logları                     │
 │        ▼                                           │
 │  Wazuh single-node (manager · indexer · dashboard)│
 └───────────────────────────────────────────────────┘
   Tüm portlar yalnızca 127.0.0.1'e bağlı · iç ağ internete çıkışsız
```

## Öne çıkan bulgular (7 doğrulanmış zafiyet)
| ID | Bulgu | Önem | Durum |
|---|---|---|---|
| F-01 | SQLi ile kimlik doğrulama atlatma (parolasız admin) | 🔴 Kritik | kod önerisi |
| F-02 | Ürün aramada SQLi + hata ifşası | 🟠 Yüksek | kod önerisi |
| F-04 | Hassas dosya ifşası (`/ftp`, KeePass DB) | 🟠 Yüksek | ✅ nginx |
| F-03 | Yetkisiz veri ifşası (`/api/Feedbacks`) | 🟡 Orta | kod önerisi |
| F-05 | Açık yönlendirme (izin listesi atlatma) | 🟡 Orta | ✅ nginx |
| F-07 | Eksik güvenlik başlıkları (CSP…) | 🟡 Orta | ✅ nginx |
| F-06 | Gevşek CORS (`ACAO: *`) | 🔵 Düşük | ✅ nginx |

Her bulgu: [Findings/](Findings/) — açıklama, yeniden üretme adımları, kanıt, etki, OWASP kategorisi,
Wazuh tespiti ve düzeltme.

## Fazlar
| # | Faz | Çıktı |
|---|---|---|
| 0–1 | Planlama + izole lab kurulumu | [lab/](lab/) · [SCOPE.md](SCOPE.md) |
| 2 | Keşif (nmap, ffuf) | [Reconnaissance/](Reconnaissance/) |
| 3 | Zafiyet analizi (ZAP + elle doğrulama) | [Vulnerability-Analysis/](Vulnerability-Analysis/) · [Findings/](Findings/) |
| 4 | Tespit mühendisliği (özel Wazuh kuralları) | [Detection/](Detection/) |
| 5 | Ağ trafiği analizi (tshark) | [Network-Analysis/](Network-Analysis/) |
| 6 | Düzeltme + yeniden test (nginx) | [Remediation/](Remediation/) |
| 7 | Rapor | [Report/](Report/) |

## Bu projede gösterilen yetkinlikler
- **Saldırı:** SQL injection, açık yönlendirme, erişim kontrolü testi, keşif, içerik keşfi
- **Savunma:** SIEM (Wazuh) kurulumu, özel tespit kuralı yazımı, log analizi, savunma derinliği
- **Ağ:** paket yakalama ve analiz (tshark), ters vekil mimarisi, Docker ağ izolasyonu
- **Düzeltme:** nginx sertleştirme (CSP, güvenlik başlıkları), önce/sonra doğrulama
- **Metodoloji:** yalnızca doğrulanmış bulguların raporlanması, yanlış pozitif ayıklama, dürüst kör nokta belgeleme

## Öne çıkan metodoloji ilkeleri
- **Yalnızca gerçekten yapılan testler belgelendi.** Araç çıktıları körü körüne kabul edilmedi.
- **Yanlış pozitifler elle doğrulandı** (ör. nmap "açık proxy" uyarısı — lab dışına trafik çıkmadığı kanıtlandı).
- **Kör noktalar dürüstçe raporlandı** (ör. gövde tabanlı SQLi access log'da görünmez → paket yakalamayla gösterildi).
- **Sorumlu test:** parola tablosu çekilmedi, KeePass açılmadı, token'lar maskelendi, DoS yapılmadı.

## Laboratuvarı çalıştırma
```bash
# Hedef katman (Juice Shop + nginx)
cd lab && docker compose up -d

# Wazuh (ilk kurulum için lab/README.md'deki sertifika adımı)
lab/wazuh/wazuh.sh up -d
```
Erişim: Juice Shop `http://127.0.0.1:8080` · Wazuh panosu `https://127.0.0.1`
Ayrıntı: [lab/README.md](lab/README.md)

## Yasal uyarı
Bu proje yalnızca kişinin kendi kontrolündeki izole bir lab ortamında, eğitim ve portföy amacıyla
yapılmıştır. Anlatılan teknikleri izin alınmamış sistemlere uygulamak yasa dışıdır.

---
<sub>🤖 Değerlendirme ve dokümantasyon, Claude Code eşliğinde yürütülmüştür.</sub>
