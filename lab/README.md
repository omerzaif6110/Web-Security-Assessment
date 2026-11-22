# Lab

| Bileşen | İmaj | Ağ / IP | Erişim |
|---|---|---|---|
| Juice Shop | `bkimminich/juice-shop:v20.4.0` | `wsa-lab-internal` 172.30.10.10 | Doğrudan yayınlanmıyor |
| nginx reverse proxy | `nginx:1.30.7-alpine` | 172.30.10.20 + `wsa-lab-edge` 172.30.20.20 | http://127.0.0.1:8080 |
| Wazuh single-node (manager, indexer, dashboard) | `wazuh/*:4.14.10` | `wsa-wazuh` 172.30.30.0/24 | https://127.0.0.1 (dashboard) |

**Kapsam içi alt ağlar:** `172.30.10.0/24`, `172.30.20.0/24`, `172.30.30.0/24`. Bkz. [SCOPE.md](../SCOPE.md)

## Wazuh ilk kurulum (yeni makinede bir kez)
```bash
git clone --depth 1 --branch v4.14.10 https://github.com/wazuh/wazuh-docker.git lab/wazuh/upstream
docker compose -f lab/wazuh/upstream/single-node/generate-indexer-certs.yml run --rm generator
lab/wazuh/wazuh.sh up -d     # ilk açılış birkaç dakika sürer
```
Değişikliklerimiz: [wazuh/docker-compose.override.yml](wazuh/docker-compose.override.yml),
[wazuh/wazuh_manager.conf](wazuh/wazuh_manager.conf) (resmi dosya + nginx `localfile`).
Dashboard'da varsayılan kimlik bilgileri kullanılıyor (kabul edilmiş risk, yalnızca loopback).

## Komutlar
```bash
cd lab
docker compose up -d          # başlat
docker compose ps             # durum
docker compose logs -f nginx  # canlı log
docker compose down           # durdur (veriler kalmaz; Juice Shop her başlangıçta sıfırlanır)
```

nginx access logları: `lab/logs/nginx/access.log` (repoya girmez).
