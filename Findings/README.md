# Bulgular (Findings)

Her bulgu elle doğrulandı; yalnızca gerçekten yeniden üretilenler listelenir.
Yöntem ve tarama ayrıntıları: [../Vulnerability-Analysis/README.md](../Vulnerability-Analysis/README.md)

| ID | Başlık | Önem | OWASP | Wazuh tespiti | Durum |
|---|---|---|---|---|---|
| [F-01](F-01-sqli-auth-bypass.md) | SQLi ile giriş atlatma | Kritik | A03 Injection | ❌ | Doğrulandı |
| [F-02](F-02-sqli-product-search.md) | Ürün aramada SQLi + hata ifşası | Yüksek | A03 Injection | ⚠️ kısmi | Doğrulandı |
| [F-03](F-03-broken-access-feedbacks.md) | `/api/Feedbacks` yetkisiz veri ifşası | Orta | A01 Broken Access | ❌ | Doğrulandı |
| [F-04](F-04-sensitive-file-exposure-ftp.md) | `/ftp` hassas dosya ifşası (KeePass) | Yüksek | A01/A05 | ⚠️ kısmi | Doğrulandı |

**Hedef:** 6-8 bulgu. Sıradaki adaylar (henüz doğrulanmadı): eksik güvenlik başlıkları (CSP, ZAP pasif),
gevşek CORS (`Access-Control-Allow-Origin: *`), `/redirect` açık yönlendirme, depolanmış XSS (`/api/Feedbacks`
veya ürün yorumları), `/api/Products` üzerinden IDOR.

**Düzeltme ve yeniden test:** Faz 6'da her bulgu için yapılacak.
