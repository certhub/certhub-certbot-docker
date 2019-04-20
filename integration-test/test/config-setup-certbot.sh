#!/bin/sh

set -e
set -u
set -x

CONFIG_CSR_DIR=$(dirname "${CONFIG_CSR_PATH}")
mkdir -p "${CONFIG_CSR_DIR}"
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 | \
    openssl req -new -subj "/CN=${CONFIG_CERT_CN}/" -key - -out "${CONFIG_CSR_PATH}"

CONFIG_CERTBOT_INI_DIR=$(dirname "${CONFIG_CERTBOT_INI_PATH}")
mkdir -p "${CONFIG_CERTBOT_INI_DIR}"

cat <<EOF > "${CONFIG_CERTBOT_INI_PATH}"
server=https://acme-staging-v02.api.letsencrypt.org/directory
manual=true
manual-public-ip-logging-ok=true
manual-auth-hook=/usr/local/lib/certhub/certbot-hooks/lexicon-auth
manual-cleanup-hook=/usr/local/lib/certhub/certbot-hooks/lexicon-cleanup
preferred-challenges=dns-01
agree-tos=true
register-unsafely-without-email=true
EOF
