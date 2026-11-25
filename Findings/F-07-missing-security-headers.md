# F-07 — Eksik Güvenlik Başlıkları (CSP, Referrer-Policy, Permissions-Policy)

| | |
|---|---|
| **Önem** | Orta |
| **OWASP Top 10 (2021)** | A05:2021 — Security Misconfiguration |
| **CWE** | CWE-693 (Protection Mechanism Failure), CWE-1021 (Clickjacking) |
| **Konum** | HTTP yanıt başlıkları (uygulama geneli) |
| **Durum** | ✅ Doğrulandı (elle + ZAP pasif) · 2026-11-25 |

## Açıklama
Yanıtlarda önemli güvenlik başlıklarının bir kısmı eksik. En kritiği **Content-Security-Policy**; bu başlık
olmadan tarayıcı tabanlı saldırılara (özellikle XSS) karşı önemli bir savunma katmanı yok.

## Kanıt (yanıt başlıkları)
| Başlık | Durum |
|---|---|
| Content-Security-Policy | ✗ **YOK** |
| Referrer-Policy | ✗ YOK |
| Permissions-Policy | ✗ YOK (yerine eski `Feature-Policy: payment 'self'` var) |
| Strict-Transport-Security | ✗ YOK (lab HTTP olduğu için şimdilik beklenen; üretimde TLS ile gerekli) |
| X-Frame-Options | ✓ VAR (`SAMEORIGIN`) |
| X-Content-Type-Options | ✓ VAR (`nosniff`) |

```
curl -D - -o /dev/null http://127.0.0.1:8080/
```
Mevcut iki başlık (`X-Frame-Options`, `X-Content-Type-Options`) **uygulama** tarafından ekleniyor;
nginx yapılandırmasında hiç `add_header` yok (Faz 6'da nginx düzeltmesi için uygun zemin).

## Etki
- **CSP yok:** Bir XSS bulgusu olması durumunda tarayıcı tarafı hiçbir ek savunma devrede değil; etki büyür.
- **Referrer-Policy yok:** URL'lerdeki hassas bilgiler Referer başlığıyla üçüncü taraflara sızabilir.
- **Permissions-Policy yok:** Tarayıcı özelliklerine (kamera, konum vb.) erişim kısıtlanmıyor.

## Wazuh'ta tespit
❌ Başlık eksikliği log üzerinden tespit edilmez; pasif tarama / yapılandırma denetimi gerektirir.

## Düzeltme (Faz 6'da nginx ile — önce/sonra karşılaştırması bu bulguya göre)
```nginx
add_header Content-Security-Policy "default-src 'self'; ..." always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Permissions-Policy "geolocation=(), camera=(), microphone=()" always;
# üretimde TLS + Strict-Transport-Security
```
Not: CSP, SPA'yı bozmadan uygulanabilmesi için uygulamanın gerçek kaynaklarına göre ayarlanmalı.
