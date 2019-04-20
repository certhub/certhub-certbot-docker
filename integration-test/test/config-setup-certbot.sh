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
--manual
--manual-auth-hook /usr/lib/certhub/certbot-hooks/lexicon-auth
--manual-cleanup-hook /usr/lib/certhub/certbot-hooks/lexicon-cleanup
--manual-public-ip-logging-ok
--preferred-challenges dns-01
--server https://acme-staging-v02.api.letsencrypt.org/directory
EOF
