# F-02 — Ürün Aramada SQL Injection + Ayrıntılı SQL Hata İfşası

| | |
|---|---|
| **Önem** | Yüksek |
| **OWASP Top 10 (2021)** | A03:2021 — Injection |
| **CWE** | CWE-89 (SQL Injection), CWE-209 (Hata Mesajıyla Bilgi İfşası) |
| **Konum** | `GET /rest/products/search?q=` |
| **Durum** | ✅ Doğrulandı (elle) · 2026-11-25 |

## Açıklama
Arama parametresi `q`, bir `LIKE '%...%'` cümlesi içine doğrudan yerleştiriliyor. Tek tırnak
eklemek SQL sözdizimini bozup sorguyu çökertiyor ve sunucu **tam SQL hata mesajını** istemciye
döndürüyor. Bu, hem enjeksiyonu kanıtlıyor hem de veritabanı türü/sorgu yapısı hakkında bilgi sızdırıyor.

## Yeniden üretme
```
# normal arama:
curl 'http://127.0.0.1:8080/rest/products/search?q=apple'      # HTTP 200, 3 ürün

# enjeksiyon testi (tek tırnak):
curl 'http://127.0.0.1:8080/rest/products/search?q=test%27'    # HTTP 500
```

## Kanıt
500 cevabının gövdesi tam hata başlığını içeriyor:
```
Error: SQLITE_ERROR: near "'%'": syntax error
```
Bu çıktıdan öğrenilenler: veritabanı **SQLite**, parametre bir `LIKE '%q%'` kalıbında kullanılıyor,
girdi metinsel olarak sorguya ekleniyor. Bu, UNION tabanlı veri çekimine (ör. kullanıcı tablosu)
olanak tanıyan klasik bir enjeksiyon noktası. **Sorumlu test gereği tüm kullanıcı/parola tablosu
çekilmedi**; enjeksiyonun varlığı hata sızıntısı ve sözdizimi kırılmasıyla kanıtlandı.

## Etki
- Veritabanından yetkisiz veri okuma (kullanıcı e-postaları, parola hash'leri dahil olabilir).
- Ayrıntılı hata mesajları saldırıya yol gösteriyor (keşif kolaylaşıyor).

## Wazuh'ta tespit
⚠️ **Kısmen.** Enjeksiyon denemesi HTTP 500 ürettiği için "Web server 500 error" alarmı (31120/31122)
çıkıyor, ama "SQL injection" olarak sınıflanmıyor. → Faz 4: `q` parametresinde SQLi kalıpları +
`SQLITE_ERROR` yanıtı için özel kural.

## Düzeltme
- Parametreli sorgu kullan (LIKE kalıbında da bağlama parametresi).
- Üretimde ayrıntılı hata mesajlarını kapat; istemciye genel hata, ayrıntı yalnızca sunucu loguna.
- Faz 6: nginx `server_tokens off` ve hata sayfası sadeleştirme yardımcı olur ama kök düzeltme kodda.
