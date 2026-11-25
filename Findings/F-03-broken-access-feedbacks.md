# F-03 — Kimlik Doğrulamasız Veri İfşası (`/api/Feedbacks`)

| | |
|---|---|
| **Önem** | Orta |
| **OWASP Top 10 (2021)** | A01:2021 — Broken Access Control |
| **CWE** | CWE-284 (Improper Access Control), CWE-200 (Bilgi İfşası) |
| **Konum** | `GET /api/Feedbacks` |
| **Durum** | ✅ Doğrulandı (elle) · 2026-11-25 |

## Açıklama
`/api/Feedbacks` uç noktası, **hiçbir kimlik doğrulaması olmadan** tüm müşterilerin geri
bildirimlerini döndürüyor. Kayıtlar `UserId` ile farklı kullanıcılara bağlanabiliyor ve bazı
yorumlar kısmen maskeli e-posta adresleri içeriyor.

Not: `/api/Users`, `/api/Cards`, `/rest/basket/` gibi uç noktalar doğru biçimde **401** döndürüyor;
yani uygulamanın erişim kontrolü var ama `/api/Feedbacks` üzerinde eksik/yanlış uygulanmış.

## Yeniden üretme
```
curl http://127.0.0.1:8080/api/Feedbacks        # HTTP 200, kimlik doğrulama yok
```

## Kanıt
- 8 geri bildirim döndü; alanlar: `UserId, id, comment, rating, createdAt, updatedAt`.
- `UserId` dağılımı: `{1, 2, 3, 21, None}` → birden fazla farklı müşteriye ait kayıtlar.
- Yorumların 4'ü kısmen maskeli e-posta içeriyor, ör: `...Highly recommended! (***in@ju...)`
  (muhtemelen `admin@juice-sh.op`; maskeleme zayıf ve tahmin edilebilir).

## Etki
- Kimliği doğrulanmamış herkes müşteri geri bildirimlerini ve dolaylı olarak kullanıcı kimliklerini
  (UserId, kısmi e-posta) görebiliyor. Tek başına düşük-orta, ama diğer bulgularla (F-01) birleşince
  kullanıcı numaralandırmasına katkı sağlar.

## Wazuh'ta tespit
❌ **Tespit edilmedi.** İstek HTTP 200 (başarılı GET) olduğu için alarm yok. → Faz 4: hassas API
uç noktalarına (`/api/Feedbacks`, `/api/Users`…) kimlik doğrulamasız (Authorization başlıksız)
erişim için kural fikri — ancak bu, nginx logundan başlık görünürlüğü gerektirir.

## Düzeltme
- Uç noktaya erişim kontrolü ekle: yalnızca yetkili kullanıcı kendi geri bildirimini görsün;
  liste uç noktası yönetici yetkisi istesin.
- Yanıttan `UserId` ve e-posta gibi alanları kaldır; maskeleme yerine alanı hiç döndürme.
