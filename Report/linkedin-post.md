# LinkedIn Yazısı (taslak)

> Kopyalayıp kullanabilirsin. `[Adın]`, repo linki ve istersen ekran görüntüsü ekle.
> İki sürüm var: kısa ve uzun. Kendi sesinle biraz düzenlemen en iyisi — yapay zekâ kokmasın.

---

## Sürüm 1 — Kısa

🛡️ Yeni bir portföy projesini tamamladım: tek bir Kali VM içinde, Docker ile kurduğum izole bir
laboratuvarda **uçtan uca bir web güvenliği değerlendirmesi.**

Hedefim sadece "zafiyet bulmak" değildi. Bir saldırının tüm yaşam döngüsünü yaşamak istedim:

🔴 Saldırı → 🔵 Tespit → 🌐 Trafik analizi → 🔧 Düzeltme → ✅ Yeniden test → 📄 Rapor

OWASP Juice Shop'a karşı **7 zafiyet** doğruladım (en kritiği: parola bilmeden admin girişi sağlayan bir
SQL injection). Ama benim için asıl öğretici kısım savunma tarafı oldu:

➡️ Saldırılarımın çoğunu Wazuh (SIEM) **görmedi.** Nedenini araştırıp **kendi tespit kurallarımı** yazdım.
➡️ Bir saldırı access log'da hiç görünmüyordu; Wireshark ile paketi açınca yükün orada olduğunu gösterdim.
➡️ nginx'te düzeltmeleri yapıp "önce/sonra" test ettim — hem engelleme hem tespit aynı anda çalıştı.

En çok şunu öğrendim: **araçların çıktısına körü körüne güvenilmez.** Yanlış pozitifleri elenemek ve
tespit edemediğin şeyi dürüstçe "kör nokta" diye yazmak, bir aracı çalıştırmaktan daha değerli.

Tüm metodoloji, bulgular, tespit kuralları ve rapor GitHub'da 👇
[repo linki]

#siberguvenlik #cybersecurity #pentest #bluetesttakımı #wazuh #owasp #docker

---

## Sürüm 2 — Uzun (daha çok teknik detay)

🛡️ **Uçtan uca web güvenliği lab'ı — portföy projesi**

Son birkaç gündür üzerinde çalıştığım projeyi paylaşmak istiyorum. Amacım, gerçek bir güvenlik
değerlendirmesinin tüm aşamalarını tek bir izole lab'da deneyimlemekti.

**Kurulum:** Tek Kali VM, Docker Compose ile izole ağ. OWASP Juice Shop (hedef) + nginx ters vekil +
Wazuh SIEM. Her şey yalnızca loopback'e bağlı, iç ağ internete çıkışsız — dışarıya tek paket gitmeden.

**Ne yaptım:**
🔍 Keşif (nmap, ffuf) — ve araçların yanlış pozitiflerini elle doğrulama
🎯 7 zafiyet: SQLi ile kimlik doğrulama atlatma (kritik), aramada SQLi, açık yönlendirme, hassas dosya
    ifşası (herkese açık bir KeePass veritabanı!), yetkisiz veri erişimi, CORS, eksik güvenlik başlıkları
🔵 Wazuh'ta özel tespit kuralları — çünkü hazır kurallar saldırılarımın çoğunu kaçırıyordu
🌐 Wireshark ile paket analizi — access log'un göremediği gövde tabanlı saldırıyı telde gösterdim
🔧 nginx'te düzeltme + "önce/sonra" yeniden test
📄 Profesyonel rapor

**En değerli üç dersim:**
1️⃣ Otomatik tarayıcılar yanıldı (yanlış pozitif + eksik sonuç). Elle doğrulama şart.
2️⃣ Tek bir görünürlük katmanı yetmiyor. Access log bir saldırıyı göremedi, paket yakalama gördü.
3️⃣ Önleme ve tespit birlikte çalışmalı. Saldırgan hem durdurulmalı (nginx) hem loglanmalı (Wazuh).

Ve belki en önemlisi: tespit edemediğim şeyleri "kör nokta" olarak dürüstçe yazdım. Bir raporu güçlü
yapan, neyi bulduğun kadar neyi bulamadığını da bilmen.

Tüm çalışma — metodoloji, ham çıktılar, tespit kuralları, önce/sonra kanıtları ve PDF rapor — GitHub'da:
👉 [repo linki]

Geri bildirime açığım, özellikle bu alanda deneyimli olanlardan. 🙏

#siberguvenlik #cybersecurity #pentesting #blueteam #redteam #wazuh #siem #owasp #juiceshop #docker #wireshark
