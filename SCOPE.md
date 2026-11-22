# SCOPE — Rules of Engagement

> Bu belge, projede **neyin test edilebileceğini, neyin kesinlikle test edilemeyeceğini** tanımlar.
> Gerçek bir sızma testinde müşteriyle imzalanan "angajman kuralları"nın lab karşılığıdır.

## 1. Amaç
Kasıtlı olarak zafiyetli bırakılmış bir web uygulamasına (OWASP Juice Shop) karşı uçtan uca bir
güvenlik değerlendirmesi yapmak: keşif → zafiyet analizi → tespit (Wazuh) → trafik analizi
(Wireshark) → düzeltme → yeniden test → raporlama. Proje eğitim/portföy amaçlıdır.

## 2. Kapsam içi (In Scope)
| Varlık | Açıklama |
|---|---|
| OWASP Juice Shop konteyneri | Tek hedef uygulama |
| nginx reverse proxy konteyneri | Juice Shop önündeki proxy; yapılandırması düzeltme aşamasında değiştirilebilir |
| Wazuh single-node konteynerleri | Yalnızca tespit amaçlı; saldırı hedefi **değildir** |
| Lab Docker ağı | Yalnızca Docker Compose ile oluşturulan izole bridge ağı (alt ağ Faz 1'de buraya yazılacak) |

**Saldırı kaynağı:** Yalnızca aynı Kali VM.

## 3. Kapsam dışı (Out of Scope) — kesinlikle yasak
- İnternet üzerindeki **herhangi bir** IP, alan adı veya servis
- Ev/okul/iş ağındaki diğer cihazlar (LAN), router, VM host makinesi
- Kali VM'in kendi Docker dışı servisleri
- Wazuh bileşenlerine yönelik saldırılar (Wazuh gözlemci rolündedir)
- DoS / yük testi / kaynak tüketme saldırıları
- Juice Shop dışındaki üçüncü taraf servislere (ör. OAuth sağlayıcıları) giden istekler

## 4. Teknik güvenceler
- Lab ağı Docker Compose'da `internal`/izole bridge olarak tanımlanacak; hedef portlar yalnızca
  `127.0.0.1`'e bağlanacak (`0.0.0.0` değil), böylece LAN'dan erişilemeyecek.
- Her tarama komutu hedefi **açıkça** belirtecek (`localhost` / lab alt ağı); aralık taraması
  yalnızca lab alt ağıyla sınırlı olacak.
- Taramadan önce hedef IP'nin lab ağına ait olduğu `docker network inspect` ile doğrulanacak.

## 5. Belgeleme kuralları
- **Yalnızca gerçekten yapılmış testler** belgelenir. Yapılmamış bir test "yapıldı" gibi yazılmaz.
- Her bulgu: kullanılan komut/istek, tarih, ekran görüntüsü (`tools/screenshot.sh`) ve kanıt içerir.
- Parola, token, oturum çerezi gibi sırlar dosyalara **yazılmaz**; ekran görüntülerinde maskelenir.
- Ham pcap ve büyük loglar repoya eklenmez (`.gitignore`); yalnızca temizlenmiş özetler eklenir.

## 6. Durdurma koşulları
Aşağıdakilerden biri olursa test durur ve PROJECT-LOG.md'ye not düşülür:
- Kapsam dışı bir hedefe trafik gittiğinden şüphelenilirse
- Lab ağı yalıtımı bozulursa (ör. port `0.0.0.0`'a açılırsa)
- VM/host kararsızlaşırsa

## 7. Onay
| Rol | İsim | Tarih |
|---|---|---|
| Test eden / lab sahibi | _(doldurulacak)_ | 2026-11-22 |
