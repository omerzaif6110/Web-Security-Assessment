# Faz 2 — Hedef doğrulama (tarama öncesi)

**Tarih:** 2026-11-23 · **Yöntem:** `docker network inspect` + `ip -4 -br addr` (SCOPE.md §4 gereği tarama öncesi)

## Lab ağları
| Ağ | Alt ağ | Gateway | internal | Konteynerler |
|---|---|---|---|---|
| wsa-lab-internal | 172.30.10.0/24 | 172.30.10.1 | true | juice-shop 172.30.10.10, nginx-proxy 172.30.10.20 |
| wsa-lab-edge | 172.30.20.0/24 | 172.30.20.1 | false | nginx-proxy 172.30.20.20 |
| wsa-wazuh | 172.30.30.0/24 | 172.30.30.1 | false | dashboard .2, indexer .3, manager .4 |

## Kapsam kararı
| Hedef | Ne | Karar |
|---|---|---|
| 172.30.10.0/24, 172.30.20.0/24 | Lab hedef ağları | ✅ Kapsam içi |
| 127.0.0.1 **yalnızca tcp/8080** | nginx'in host'a yayını | ✅ Kapsam içi |
| 172.30.10.1, 172.30.20.1 | Kali'nin kendi köprü arayüzleri (gateway) | ❌ Hariç (`--exclude`) — Kali'yi taramak kapsam dışı |
| 172.30.30.0/24 | Wazuh | ❌ Hariç — gözlemci, saldırı hedefi değil |
| 127.0.0.1 diğer portlar | Wazuh dashboard 443, Tor 9050, geçici portlar | ❌ Hariç |
| 172.18.0.0/16 (br-…, DOWN) | Sertifika üreticisinin (`docker compose run`) bıraktığı boş varsayılan ağ | ❌ Hariç (lab değil) |

## Araç
- nmap 7.99; `/usr/lib/nmap/nmap` üzerinde `cap_net_raw,cap_net_admin,cap_net_bind_service` var
  → sudo olmadan `--privileged` ile SYN taraması ve ARP keşfi yapılabiliyor.
