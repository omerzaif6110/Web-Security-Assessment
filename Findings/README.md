# Bulgular (Findings)

Her bulgu elle doğrulandı; yalnızca gerçekten yeniden üretilenler listelenir.
Yöntem ve tarama ayrıntıları: [../Vulnerability-Analysis/README.md](../Vulnerability-Analysis/README.md)

| ID | Başlık | Önem | OWASP | Wazuh tespiti | Durum |
|---|---|---|---|---|---|
| [F-01](F-01-sqli-auth-bypass.md) | SQLi ile giriş atlatma | Kritik | A03 Injection | ❌ | Doğrulandı |
| [F-02](F-02-sqli-product-search.md) | Ürün aramada SQLi + hata ifşası | Yüksek | A03 Injection | ⚠️ kısmi | Doğrulandı |
| [F-03](F-03-broken-access-feedbacks.md) | `/api/Feedbacks` yetkisiz veri ifşası | Orta | A01 Broken Access | ❌ | Doğrulandı |
| [F-04](F-04-sensitive-file-exposure-ftp.md) | `/ftp` hassas dosya ifşası (KeePass) | Yüksek | A01/A05 | ⚠️ kısmi | Doğrulandı |
| [F-05](F-05-open-redirect.md) | Açık yönlendirme (izin listesi atlatma) | Orta | A01 | ❌ | Doğrulandı |
| [F-06](F-06-cors-misconfig.md) | Gevşek CORS (`ACAO: *`) | Düşük | A05 | ❌ | Doğrulandı |
| [F-07](F-07-missing-security-headers.md) | Eksik güvenlik başlıkları (CSP…) | Orta | A05 | ❌ | Doğrulandı |

**7 bulgu doğrulandı (hedef 6-8 ✅).** İncelenen ama kanıtlanmak için ek kurulum gerektiren adaylar
(captcha/oturum): depolanmış XSS (geri bildirim/yorum), `/rest/basket/:id` IDOR — Faz 6 sonrası veya
derinleştirme turunda ele alınabilir.

**Düzeltme ve yeniden test:** Faz 6'da her bulgu için yapılacak.
