#!/bin/bash
set -euo pipefail

mkdir -p /etc/trino/catalog

cat > /etc/trino/catalog/postgres.properties <<EOF
connector.name=postgresql
connection-url=jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_INTERNAL_PORT}/${POSTGRES_DB}
connection-user=${POSTGRES_USER}
connection-password=${POSTGRES_PASSWORD}
EOF

cat > /etc/trino/catalog/clickhouse.properties <<EOF
connector.name=clickhouse
connection-url=jdbc:clickhouse://${CLICKHOUSE_HOST}:${CLICKHOUSE_INTERNAL_PORT}/
connection-user=${CLICKHOUSE_USER}
connection-password=${CLICKHOUSE_PASSWORD}
clickhouse.map-string-as-varchar=true
EOF

exec /usr/lib/trino/bin/run-trino
