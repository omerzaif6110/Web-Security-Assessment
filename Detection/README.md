# Faz 4 — Wazuh Tespit Kuralları

**Tarih:** 2026-11-25 · **Kural dosyası:** [rules/local_rules.xml](rules/local_rules.xml)
**Bağlanış:** `lab/wazuh/docker-compose.override.yml` ile manager'a salt okunur mount (repodan, kalıcı).

## Amaç
Faz 3'te saldırıların çoğu Wazuh'ta görünmedi. İki neden:
1. Hazır SQLi kuralı (31103) **anahtar kelime** (`select`, `union`, `where`) arıyor; bizim tırnak/boolean
   tabanlı SQLi'miz (`q=test'`, `' OR 1=1--`) bu kelimeleri içermiyordu.
2. Uygulamaya özel saldırılar (`/ftp/*.kdbx`, `/redirect?to=`) hiçbir hazır kurala uymuyordu.

Bu faz, Faz 3 bulgularına karşılık gelen özel kurallar yazıp **uçtan uca** (canlı istek → nginx → Wazuh →
indexer) doğruluyor.

## Kurallar
| ID | Seviye | Yakaladığı | Faz 3 bulgusu | MITRE |
|---|---|---|---|---|
| 100101 | 10 | URL'de tırnak/boolean SQLi (`%27`, `or`, `--`, `union select`) | F-02 | T1190 |
| 100110 | 10 | `/ftp` altında hassas uzantı (`.kdbx`, `.bak`, `.pyc`, `.key`, `.pem`…) | F-04 | T1083, T1552.001 |
| 100120 | 8 | Açık yönlendirme denemesi (`/redirect?to=` dış http/https) | F-05 | T1190 |

Tasarım notları:
- `if_sid>31100,31108</if_sid>`: nginx access log temel kuralı **ve** "basit istek" kuralı (31108).
  İkincisi şart: basit GET istekleri (ör. kdbx indirme) 31108'e düşüyor; sadece 31100'e bağlı kural tetiklenmezdi
  (bunu test ederken öğrendik, hazır 31103 de aynı yöntemi kullanıyor).
- `<url type="pcre2">`: `url` Wazuh'ta yerleşik alan; `<field name="url">` ile kullanılamıyor (hata verir),
  `<url>` etiketiyle pcre2 kullanılmalı.

## Doğrulama

### 1) Birim testi (`wazuh-logtest`)
Her kural örnek satırlarla tek tek test edildi. Doğru pozitifler tetiklendi, **normal istekler tetiklemedi**:
| Girdi | Beklenen | Sonuç |
|---|---|---|
| `GET /rest/products/search?q=test%27` | 100101 | ✅ |
| `GET /rest/products/search?q=a%27%20or%201=1--` | 100101 | ✅ |
| `GET /ftp/incident-support.kdbx` | 100110 | ✅ |
| `GET /ftp/package.json.bak` | 100110 | ✅ |
| `GET /redirect?to=https://example.com/x` | 100120 | ✅ |
| `GET /rest/products/search?q=apple` (normal) | alarm yok | ✅ |
| `GET /ftp/legal.md` (hassas değil) | alarm yok | ✅ |

### 2) Uçtan uca (canlı istek → indexer)
İşaretli User-Agent ile 3 saldırı `127.0.0.1:8080`'e atıldı; ~8 sn içinde indexer'da üçü de bulundu:
```
kural 100101 (sev 10) - SQL injection ... url: /rest/products/search?q=test%27
kural 100110 (sev 10) - /ftp hassas dosya ... url: /ftp/incident-support.kdbx
kural 100120 (sev 8)  - Açık yönlendirme ... url: /redirect?to=https://example.com/x
```
Not: açık yönlendirme isteği 406 (izin listesi reddi) dönse bile kural **denemeyi** yakalıyor — tespit için
istenen davranış.

## Kör noktalar (dürüst sınırlar)
Bu kurallar nginx **access log**'una dayanır; access log yalnızca istek satırını (metot, URL, durum) görür.
Bu nedenle **yakalanamayan**lar:
- **F-01 giriş SQLi (`' OR 1=1--`):** yük istek **gövdesinde** (`POST /rest/user/login` body'si). Access log
  gövdeyi görmez; üstelik başarılı atlatma 200 döner. Yakalamak için seçenekler:
  - nginx'i istek gövdesini loglayacak şekilde ayarlamak → **ama bu parolaları da loglar** (yeni risk), önerilmez.
  - Uygulama seviyesinde loglama / JWT "yeni oturum" olaylarını Wazuh'a beslemek.
  - Bir WAF (ör. ModSecurity) ile gövde denetimi.
- **F-03 (`/api/Feedbacks`), F-06 (CORS), F-07 (başlıklar):** başarılı 200 ya da yapılandırma; access log'dan
  "saldırı" olarak ayırt edilemez. Bunlar tespit değil, **önleme** (Faz 6) konusu.

## Sıradaki (Faz 5/6 girdisi)
- Faz 5: bu alarmlara karşılık gelen trafiği Wireshark'ta incele.
- Faz 6: F-04/F-05'i nginx'te engelle (kural artık "engellendi" olayını da görebilir); F-01 için kök düzeltme kodda.
- Olası iyileştirme: aynı IP'den kısa sürede çok sayıda WSA alarmı → "aktif tarama" korelasyon kuralı.
