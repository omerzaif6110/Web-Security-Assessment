# F-05 — Açık Yönlendirme (Open Redirect) — İzin Listesi Atlatma

| | |
|---|---|
| **Önem** | Orta |
| **OWASP Top 10 (2021)** | A01:2021 — Broken Access Control (URL yönlendirme) |
| **CWE** | CWE-601 (URL Redirection to Untrusted Site) |
| **Konum** | `GET /redirect?to=` |
| **Durum** | ✅ Doğrulandı (elle) · 2026-11-25 |

## Açıklama
`/redirect` uç noktası, `to` parametresindeki adrese 302 yönlendirme yapıyor. Hedefin güvenli olup
olmadığını bir izin listesiyle kontrol ediyor, ama kontrol **"içinde geçiyor mu" (substring)** mantığıyla
yapıldığı için atlatılabiliyor: izinli bir URL'yi parametre olarak içeren **herhangi bir dış adrese**
yönlendirme mümkün.

## Yeniden üretme
```
# A) tam izinli hedef -> normal davranış:
curl --max-redirs 0 -i 'http://127.0.0.1:8080/redirect?to=https://github.com/juice-shop/juice-shop'
# -> 302, Location: https://github.com/juice-shop/juice-shop

# B) izinli metin hiç yok -> engelleniyor:
curl --max-redirs 0 -i 'http://127.0.0.1:8080/redirect?to=https://example.com/'
# -> 406 Not Acceptable

# C) ATLATMA - dış hedef + izinli metni parametre olarak ekle:
curl --max-redirs 0 -i \
  'http://127.0.0.1:8080/redirect?to=https://example.com/acme?pwn=https://github.com/juice-shop/juice-shop'
# -> 302, Location: https://example.com/acme?pwn=https://github.com/juice-shop/juice-shop
```

## Kanıt
- (A) 302 → github (izinli). (B) 406 (izinli metin yok → reddedildi). (C) **302 → example.com** (saldırgan
  kontrolündeki adres), çünkü izinli dize sorgu parametresi olarak mevcut. Tarayıcı `example.com`'a gider.
- Not: `example.com` yalnızca zararsız örnek hedef; gerçek bir kötü amaçlı siteye yönlendirme denenmedi.

## Etki
Kurbana güvenilir `127.0.0.1:8080` (gerçekte mağazanın alan adı) bağlantısı gönderilip saldırgan sitesine
düşürülebilir → kimlik avı (phishing), sahte giriş sayfası, kötü amaçlı indirme. Bağlantı meşru alan adıyla
başladığı için kullanıcı güveni istismar edilir.

## Wazuh'ta tespit
❌ **Tespit edilmedi.** Başarılı yönlendirme 302 döndürüyor, saldırı alarmı yok. → Faz 4: `/redirect?to=`
parametresinde dış şema (`http`/`https`) içeren istekler için kural.

## Düzeltme
- İzin listesi kontrolünü **tam eşleşme** yap (substring değil); yalnızca izin verilen tam URL'lere yönlendir.
- Daha iyisi: dışarı yönlendirmeyi tamamen kaldır ya da yalnızca göreli (`/...`) yollara izin ver.
