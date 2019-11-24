#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd "$(dirname "${0}")" &>/dev/null && pwd)/__helpers.sh"

SERVICE_ACCOUNT="vault-server@$(google-project).iam.gserviceaccount.com"

gcloud container clusters create vault \
  --project="$(google-project)" \
  --cluster-version="$(gke-latest-master-version)" \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-ip-alias \
  --machine-type="n1-standard-2" \
  --node-version="$(gke-latest-node-version)" \
  --num-nodes="1" \
  --region="$(google-region)" \
  --scopes="cloud-platform" \
  --service-account="${SERVICE_ACCOUNT}"


gcloud compute addresses create vault \
  --project="$(google-project)" \
  --region="$(google-region)"

LB_IP="$(vault-lb-ip)"

DIR="$(pwd)/tls"

rm -rf "${DIR}"
mkdir -p "${DIR}"

# Create the conf file
cat > "${DIR}/openssl.cnf" << EOF
[req]
default_bits = 2048
encrypt_key  = no
default_md   = sha256
prompt       = no
utf8         = yes
distinguished_name = req_distinguished_name
req_extensions     = v3_req
[req_distinguished_name]
C  = US
ST = California
L  = The Cloud
O  = Demo
CN = vault
[v3_req]
basicConstraints     = CA:FALSE
subjectKeyIdentifier = hash
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth, serverAuth
subjectAltName       = @alt_names
[alt_names]
IP.1  = ${LB_IP}
DNS.1 = vault.default.svc.cluster.local
EOF

# Generate Vault's certificates and a CSR
openssl genrsa -out "${DIR}/vault.key" 2048

openssl req \
  -new -key "${DIR}/vault.key" \
  -out "${DIR}/vault.csr" \
  -config "${DIR}/openssl.cnf"

# Create our CA
openssl req \
  -new \
  -newkey rsa:2048 \
  -days 120 \
  -nodes \
  -x509 \
  -subj "/C=US/ST=California/L=The Cloud/O=Vault CA" \
  -keyout "${DIR}/ca.key" \
  -out "${DIR}/ca.crt"

# Sign CSR with our CA
openssl x509 \
  -req \
  -days 120 \
  -in "${DIR}/vault.csr" \
  -CA "${DIR}/ca.crt" \
  -CAkey "${DIR}/ca.key" \
  -CAcreateserial \
  -extensions v3_req \
  -extfile "${DIR}/openssl.cnf" \
  -out "${DIR}/vault.crt"

# Export combined certs for vault
cat "${DIR}/vault.crt" "${DIR}/ca.crt" > "${DIR}/vault-combined.crt"