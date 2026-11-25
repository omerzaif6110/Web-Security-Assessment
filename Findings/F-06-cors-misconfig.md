# F-06 — Gevşek CORS Yapılandırması (`Access-Control-Allow-Origin: *`)

| | |
|---|---|
| **Önem** | Düşük |
| **OWASP Top 10 (2021)** | A05:2021 — Security Misconfiguration |
| **CWE** | CWE-942 (Overly Permissive Cross-domain Policy) |
| **Konum** | Tüm yanıtlar (uygulama geneli) |
| **Durum** | ✅ Doğrulandı (elle + ZAP pasif) · 2026-11-25 |

## Açıklama
Uygulama her yanıtta `Access-Control-Allow-Origin: *` döndürüyor. Bu, herhangi bir web sitesinin
tarayıcıdan uygulamanın yanıtlarını okumasına izin verir.

**Önem neden Düşük:** `Access-Control-Allow-Credentials` **ayarlı değil**. `ACAO: *` ile tarayıcı
çerez/kimlik bilgisi göndermeye izin vermez, dolayısıyla kimliği doğrulanmış kullanıcının verisi bu yolla
çalınamaz. Juice Shop kimliği JWT'yi `Authorization` başlığında (localStorage) taşıyor; kötü amaçlı bir
site bu başlığı otomatik ekleyemez. Etki, yalnızca kimlik doğrulaması gerektirmeyen (zaten herkese açık)
verilerle sınırlı.

## Yeniden üretme / Kanıt
```
curl -D - -o /dev/null -H "Origin: https://evil.example" http://127.0.0.1:8080/rest/products/search?q=apple
# -> Access-Control-Allow-Origin: *   (sahte Origin'e rağmen)

curl -D - -o /dev/null -H "Origin: https://evil.example" http://127.0.0.1:8080/   # Allow-Credentials YOK
```
- `ACAO: *` hem 200 hem 401 yanıtlarında mevcut; `Access-Control-Allow-Credentials` hiç yok (doğrulandı).

## Etki
Sınırlı: kimlik doğrulamasız/halka açık uç noktaların çapraz kaynak okunması. Kimlik bilgili saldırı (en
tehlikeli CORS senaryosu) mümkün değil. Yine de en az yetki ilkesine aykırı.

## Wazuh'ta tespit
❌ Başlık tabanlı yapılandırma; log üzerinden tespit edilmez (uygulama davranışı).

## Düzeltme
- `ACAO`'yu `*` yerine bilinen güvenilir kaynaklarla sınırla; gerekmiyorsa CORS'u tamamen kapat.
- Faz 6: nginx seviyesinde kontrollü CORS başlığı denenebilir.
