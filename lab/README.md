# Lab

| Bileşen | İmaj | Ağ / IP | Erişim |
|---|---|---|---|
| Juice Shop | `bkimminich/juice-shop:v20.4.0` | `wsa-lab-internal` 172.30.10.10 | Doğrudan yayınlanmıyor |
| nginx reverse proxy | `nginx:1.30.7-alpine` | 172.30.10.20 + `wsa-lab-edge` 172.30.20.20 | http://127.0.0.1:8080 |
| Wazuh single-node | _(kurulacak)_ | | |

**Kapsam içi alt ağlar:** `172.30.10.0/24`, `172.30.20.0/24` (+ Wazuh ağı, kurulunca). Bkz. [SCOPE.md](../SCOPE.md)

## Komutlar
```bash
cd lab
docker compose up -d          # başlat
docker compose ps             # durum
docker compose logs -f nginx  # canlı log
docker compose down           # durdur (veriler kalmaz; Juice Shop her başlangıçta sıfırlanır)
```

nginx access logları: `lab/logs/nginx/access.log` (repoya girmez).
