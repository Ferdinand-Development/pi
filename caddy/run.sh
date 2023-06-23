#!/bin/sh

HASHED_PASSWORD=$(caddy hash-password --plaintext "$ACCESS_PASSWORD")

cp /etc/caddy/Caddyfile /Caddyfile
sed -i "s/##USERNAME_PLACEHOLDER##/$ACCESS_USERNAME/" /Caddyfile
sed -i "s/##PASSWORD_PLACEHOLDER##/$HASHED_PASSWORD/" /Caddyfile

echo "Caddyfile"
cat /Caddyfile

echo "Running caddy"
caddy run --config /Caddyfile --adapter caddyfile
