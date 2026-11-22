#!/usr/bin/env bash
# Wazuh compose sarmalayıcısı: resmi dosya + lab override'ı birlikte kullanır.
#   lab/wazuh/wazuh.sh up -d
#   lab/wazuh/wazuh.sh ps
#   lab/wazuh/wazuh.sh logs -f wazuh.manager
#   lab/wazuh/wazuh.sh down
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$DIR/upstream/single-node/docker-compose.yml" ]] || {
  echo "Resmi depo yok. Önce:" >&2
  echo "  git clone --depth 1 --branch v4.14.10 https://github.com/wazuh/wazuh-docker.git $DIR/upstream" >&2
  exit 1
}
exec docker compose -p wsa-wazuh \
  -f "$DIR/upstream/single-node/docker-compose.yml" \
  -f "$DIR/docker-compose.override.yml" \
  "$@"
