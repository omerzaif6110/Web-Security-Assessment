# Faz 5 — Ağ Trafiği Analizi (Wireshark/tshark)

**Tarih:** 2026-11-25 · **Araç:** tshark (Wireshark CLI) · **Yakalama:** `-i any`, `tcp port 8080 or 3000`
**Yetki:** `dumpcap` capability + `wireshark` grubu → sudo gerekmedi.
**Ham pcap repoya EKLENMEZ** (`.gitignore *.pcap`; içinde kdbx dosya baytları ve JWT var). Metin kanıtları: [extracts/](extracts/)

## Amaç
Faz 3/4 saldırılarını paket seviyesinde yakalayıp göstermek: reverse proxy mimarisi trafikte nasıl görünüyor
ve **paket yakalama, nginx access log'unun göremediği neyi görüyor** (Faz 4 kör noktası).

## Yakalama
98 paket. Her istek **iki bacakta** görünüyor:
```
Kali (127.0.0.1:rastgele)  --GET/POST-->  nginx (127.0.0.1:8080)      [1. bacak, loopback]
nginx                      --GET/POST-->  juice-shop (172.30.10.10:3000)  [2. bacak, iç köprü]
```
Tekrarlanan saldırılar: normal arama, giriş SQLi (F-01), arama SQLi (F-02), kdbx indirme (F-04),
açık yönlendirme (F-05). İstek listesi: [extracts/http-requests.tsv](extracts/http-requests.tsv).

## Bulgular

### 1. En önemli: istek gövdesi pakette görünür (F-01 kör noktası kapanıyor)
Giriş SQLi'si `POST /rest/user/login` gövdesinde. tshark ile gövde (`http.file_data`) çıkarıldı (hex→metin):
```json
{"email":"' OR 1=1--","password":"x"}
```
→ **SQLi yükü trafikte açıkça görünüyor.** nginx access log yalnızca `POST /rest/user/login 200` satırını
yazar; gövdeyi göremez (Faz 4'te bu yüzden F-01 tespit edilememişti). **Ders:** gövde tabanlı saldırılar için
ağ/paket görünürlüğü (ya da uygulama logu) gerekir; access log tek başına yetmez.

### 2. Reverse proxy IP çevirisi (X-Forwarded-For)
İç bacakta (nginx→juice-shop) her istekte nginx `X-Forwarded-For: 172.30.20.1` ekliyor.
- `172.30.20.1` = edge köprüsünün gateway'i = **Kali**. Juice Shop gerçek istemciyi bu başlıktan öğreniyor.
- Bu, Faz 2/4 gözlemini açıklıyor: Wazuh'ta tüm saldırılar `172.30.20.1`'den görünüyor; çünkü kaynak IP
  bu tek değer. Gerçek ortamda birden çok istemci olsaydı XFF ayırt edici olurdu.

### 3. Hassas dosya telden geçiyor (F-04)
`/ftp/incident-support.kdbx` yanıtı: **HTTP 200, 3246 bayt, `application/octet-stream`**. KeePass veritabanı
şifresiz HTTP üzerinden tam olarak aktarıldı → ağı dinleyen biri dosyayı yeniden oluşturabilir.
(İçerik kanıt için çıkarılmadı; yalnızca aktarıldığı gösterildi.) TLS olmadığından tüm trafik düz metin.

### 4. Yanıt kodları (telde doğrulandı)
| İstek | Kod | Boyut/Tür |
|---|---|---|
| arama SQLi `q=test'` | 500 | text/html (SQL hata sayfası) |
| kdbx | 200 | 3246 B, octet-stream |
| açık yönlendirme (izinli hedef) | 302 | 62 B, text/plain |

## Sınırlar / notlar
- Lab HTTP (TLS yok); gerçek ortamda HTTPS olsaydı gövde/dosya şifreli olur, bu analiz ancak TLS anahtarı
  ile (ör. `SSLKEYLOGFILE`) mümkün olurdu. Lab'ın düz metin olması analizi kolaylaştırdı ama kendisi de bir
  bulgu (hassas veri şifresiz).
- Yakalama kapsam içi (yalnızca lab 8080/3000); başka trafik toplanmadı.

## Faz 6 bağlantısı
- F-04: `/ftp` erişimi engellenince bu dosya artık telden geçmeyecek.
- F-01: gövde tabanlı SQLi — kök düzeltme uygulama kodunda; ağ görünürlüğü yalnızca tespit sağlar.
