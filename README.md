# Web Security Assessment — OWASP Juice Shop Lab

> 🚧 **Taslak.** Proje devam ediyor; bölümler fazlar tamamlandıkça doldurulacak.

Tek bir Kali Linux VM içinde, Docker Compose ile kurulan izole bir lab üzerinde uçtan uca web
güvenliği değerlendirmesi: **saldırı → tespit → trafik analizi → düzeltme → yeniden test → rapor.**

## Mimari (planlanan)
```
 Kali (saldırgan: nmap, ZAP/Burp, Wireshark)
        │  127.0.0.1
        ▼
 ┌──────────── izole Docker ağı ────────────┐
 │  nginx (reverse proxy) ──► Juice Shop    │
 │        │ access/error logları            │
 │        ▼                                  │
 │  Wazuh single-node (manager+indexer+UI)  │
 └──────────────────────────────────────────┘
```

## Kapsam
Yalnızca bu lab ve izole Docker ağı. Dışarıya hiçbir tarama yapılmaz. Detaylar: [SCOPE.md](SCOPE.md)

## Fazlar
| # | Faz | Klasör | Durum |
|---|---|---|---|
| 0 | Planlama | — | ✅ |
| 1 | Lab kurulumu | [lab](lab/) | ✅ |
| 2 | Keşif (nmap) | [Reconnaissance](Reconnaissance/) | ✅ |
| 3 | Zafiyet analizi (ZAP/Burp) | [Vulnerability-Analysis](Vulnerability-Analysis/) | 🟡 |
| 4 | Wazuh tespit kuralları | [Detection](Detection/) | ⚪ |
| 5 | Wireshark analizi | [Network-Analysis](Network-Analysis/) | ⚪ |
| 6 | Düzeltme ve yeniden test | [Remediation](Remediation/) | ⚪ |
| 7 | Rapor | — | ⚪ |

## Bulgular
_Faz 3'te doldurulacak. Her bulgu için: önem derecesi, OWASP Top 10 kategorisi, kanıt, Wazuh'ta
tespit edildi mi, düzeltme ve yeniden test sonucu. Detaylar: [Findings](Findings/)_

## Klasör yapısı
| Klasör | İçerik |
|---|---|
| `Reconnaissance/` | nmap çıktı özetleri, servis envanteri |
| `Vulnerability-Analysis/` | ZAP/Burp analizleri |
| `Findings/` | Bulgu başına bir dosya |
| `Detection/` | Wazuh özel kuralları, alarm kanıtları |
| `Network-Analysis/` | Wireshark analiz notları (ham pcap repoda yok) |
| `Remediation/` | Düzeltmeler ve yeniden test sonuçları |
| `Screenshots/` | `tools/screenshot.sh` ile alınan kanıtlar |
| `Learning-Notes/` | Öğrendiklerim |
| `tools/` | Yardımcı scriptler |

## Araçlar
Kali Linux · Docker Compose · OWASP Juice Shop · nginx · Wazuh · nmap · OWASP ZAP · Burp Suite · Wireshark

## Yasal uyarı
Bu proje yalnızca kişinin kendi kontrolündeki izole bir lab ortamında, eğitim amacıyla yapılmıştır.
Burada anlatılan teknikleri izin almadan başka sistemlere uygulamak yasa dışıdır.
