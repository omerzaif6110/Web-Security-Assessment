# Faz 6 — Düzeltme ve Yeniden Test

**Tarih:** 2026-11-26 · **Katman:** nginx reverse proxy · **Config:** [../lab/nginx/default.conf](../lab/nginx/default.conf)
**Önce/sonra ham çıktı:** [before-after/before.txt](before-after/before.txt) · [before-after/after.txt](before-after/after.txt)

## Yaklaşım
Düzeltmeler nginx katmanında yapıldı (Juice Shop kaynak kodu değiştirilmedi — gerçek bir değerlendirmede
geliştirici ekibinin işi). nginx'in doğru biçimde çözebildiği bulgular düzeltildi; kök nedeni uygulama
kodunda olanlar (SQLi, yetkisiz erişim) "kod önerisi" olarak belgelendi. Her düzeltmeden sonra hem **bulgu
yeniden test edildi** (kapandı mı) hem de **normal işlev** kontrol edildi (bozulmadı mı).

## Düzeltilen bulgular (önce → sonra)

| Bulgu | Önce | Sonra | nginx değişikliği |
|---|---|---|---|
| **F-04** /ftp hassas dosya | `/ftp/` 200, `kdbx` 200 | **403** | `location ^~ /ftp { return 403; }` |
| **F-05** açık yönlendirme | atlatma → 302 dış adres | atlatma → **403**, meşru → 302 | `if ($arg_to ~* "://.*://") { return 403; }` |
| **F-06** gevşek CORS | `ACAO: *` | **başlık kaldırıldı** | `proxy_hide_header Access-Control-Allow-Origin;` |
| **F-07** eksik başlıklar | CSP/Referrer/Permissions yok | **üçü de eklendi** | `add_header ...` |
| **R-07** sürüm ifşası | `Server: nginx/1.30.7` | **`Server: nginx`** | `server_tokens off;` |

**Normal işlev korundu:** ana sayfa 200, arama 200, meşru giriş 401 (doğru), meşru redirect 302. SPA tarayıcıda
tam yükleniyor (ürünler, görseller, API çağrıları). Doğrulama: tarayıcı paneli + konsol (yalnızca başta bir
yazı tipi CSP'ye takıldı, aşağıya bakınız).

### CSP ayarı (gerçekçi bir ayrıntı)
İlk CSP, uygulamanın kullandığı Google Fonts'u engelledi (tarayıcı konsolunda görüldü). İyi bir CSP "her şeyi
engelle" değil, uygulamanın **meşru** ihtiyaçlarına izin verip gerisini kısıtlar. Bu yüzden `style-src`/`font-src`'e
`fonts.googleapis.com` / `fonts.gstatic.com` eklendi. SPA'lar inline script/style kullandığı için `'unsafe-inline'`
ve `'unsafe-eval'` gerekti — bu CSP'yi zayıflatır; **asıl çözüm uygulamanın nonce/hash tabanlı CSP'ye uyarlanması**,
ki bu uygulama kodu değişikliğidir. Yine de `default-src 'self'`, `connect-src 'self'`, `frame-ancestors 'self'`
(clickjacking) değer katıyor.

## Önleme + Tespit birlikte (savunma derinliği)
Düzeltmeden sonra engellenen (403) saldırılar tekrar atıldı. **Faz 4 Wazuh kuralları hâlâ tetikleniyor:**
```
kural 100110 (sev 10) - /ftp hassas dosya ... url: /ftp/incident-support.kdbx   [artık 403]
kural 100120 (sev 8)  - Açık yönlendirme ... url: /redirect?to=...               [artık 403]
```
Yani saldırgan hem **durduruluyor** (nginx) hem **loglanıyor** (Wazuh). Olgun bir savunmanın iki katmanı.

## Düzeltilmeyen bulgular — kök neden uygulama kodunda (öneri)
Bunlar nginx'te temiz düzeltilemez; kaba kalıp engelleme yanlış pozitif üretir ve gerçek çözüm değildir.

| Bulgu | Neden nginx'te değil | Kod düzeltmesi önerisi |
|---|---|---|
| **F-01** SQLi giriş atlatma | Yük istek gövdesinde; engellemek meşru girişleri de bozabilir | Parametreli sorgu / ORM bağlama; girdiyi asla SQL metnine ekleme |
| **F-02** aramada SQLi | Aynı; `q` parametresi meşru arama da taşır | Parametreli `LIKE` sorgusu; ayrıntılı hata mesajını kapat |
| **F-03** `/api/Feedbacks` yetkisiz | Yol meşru; engellemek işlevi bozar | Uç noktaya erişim kontrolü; yanıttan UserId/e-posta çıkar |

**Not:** F-01/F-02 için nginx'te defansif bir WAF kuralı (ör. `%27` + `or`/`union` engelleme) eklenebilirdi
ama kullanıcı kararıyla "temiz düzeltmeler" kapsamı seçildi; WAF hafifletmesi ayrı bir derinleştirme işi.

## Kalıcılık
nginx config repoda (`lab/nginx/default.conf`), konteynere klasör olarak bağlı (Faz 1). `docker compose up -d`
ya da reload sonrası düzeltmeler etkin. TLS hâlâ yok (lab HTTP); üretimde HSTS + TLS eklenmeli.
