# Bulgular (Findings)

Her bulgu elle doğrulandı; yalnızca gerçekten yeniden üretilenler listelenir.
Yöntem ve tarama ayrıntıları: [../Vulnerability-Analysis/README.md](../Vulnerability-Analysis/README.md)

| ID | Başlık | Önem | OWASP | Wazuh tespiti | Düzeltme (Faz 6) |
|---|---|---|---|---|---|
| [F-01](F-01-sqli-auth-bypass.md) | SQLi ile giriş atlatma | Kritik | A03 Injection | ❌ | ⏳ kod önerisi (parametreli sorgu) |
| [F-02](F-02-sqli-product-search.md) | Ürün aramada SQLi + hata ifşası | Yüksek | A03 Injection | ⚠️ kısmi | ⏳ kod önerisi |
| [F-03](F-03-broken-access-feedbacks.md) | `/api/Feedbacks` yetkisiz veri ifşası | Orta | A01 Broken Access | ❌ | ⏳ kod önerisi (erişim kontrolü) |
| [F-04](F-04-sensitive-file-exposure-ftp.md) | `/ftp` hassas dosya ifşası (KeePass) | Yüksek | A01/A05 | ⚠️ kısmi | ✅ nginx 403 |
| [F-05](F-05-open-redirect.md) | Açık yönlendirme (izin listesi atlatma) | Orta | A01 | ❌ | ✅ nginx (atlatma engellendi) |
| [F-06](F-06-cors-misconfig.md) | Gevşek CORS (`ACAO: *`) | Düşük | A05 | ❌ | ✅ nginx (başlık kaldırıldı) |
| [F-07](F-07-missing-security-headers.md) | Eksik güvenlik başlıkları (CSP…) | Orta | A05 | ❌ | ✅ nginx (CSP+2 başlık) |

Düzeltme ayrıntısı ve önce/sonra: [../Remediation/README.md](../Remediation/README.md). nginx'te düzeltilen 4
bulgu + sürüm gizleme (R-07) yeniden test edildi; SQLi/yetkisiz erişim kök nedeni uygulama kodunda (öneri).

**7 bulgu doğrulandı (hedef 6-8 ✅).** İncelenen ama kanıtlanmak için ek kurulum gerektiren adaylar
(captcha/oturum): depolanmış XSS (geri bildirim/yorum), `/rest/basket/:id` IDOR — Faz 6 sonrası veya
derinleştirme turunda ele alınabilir.

**Düzeltme ve yeniden test:** Faz 6'da her bulgu için yapılacak.
