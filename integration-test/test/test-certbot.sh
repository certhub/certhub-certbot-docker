#!/bin/sh

set -e
set -u
set -x

git gau-ac \
git gau-xargs -I"{WORKDIR}" \
certhub-message-format "${CERTHUB_CERT_PATH}" x509 \
certhub-certbot-run "${CERTHUB_CERT_PATH}" "${CERTHUB_CSR_PATH}" \
certbot ${CERTHUB_CERTBOT_ARGS} --config "${CERTHUB_CERTBOT_CONFIG}"
