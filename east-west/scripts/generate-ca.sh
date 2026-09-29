#!/usr/bin/env bash
set -euo pipefail
umask 077
root_dir="$(cd "$(dirname "$0")/../.." && pwd)"
ca_dir="$root_dir/.local/multicluster-ca"
if [ -e "$ca_dir" ]; then
echo "CA directory already exists: $ca_dir" >&2
exit 1
fi
mkdir -p "$ca_dir"
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 3650   -keyout "$ca_dir/root-key.pem" -out "$ca_dir/root-cert.pem"   -subj "/O=Istio Training/CN=Mesh Root CA"   -addext "basicConstraints=critical,CA:TRUE"   -addext "keyUsage=critical,keyCertSign,cRLSign"
openssl req -new -newkey rsa:4096 -nodes     -keyout "$ca_dir/ca-key.pem"     -out "$ca_dir/ca.csr"     -subj "/O=Istio Training/CN=Shared Intermediate CA"
cat > "$ca_dir/extensions.cnf" <<EOF
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
EOF
openssl x509 -req -sha256 -days 1825     -in "$ca_dir/ca.csr"     -CA "$ca_dir/root-cert.pem" -CAkey "$ca_dir/root-key.pem"     -CAserial "$ca_dir/root-cert.srl" -CAcreateserial     -extfile "$ca_dir/extensions.cnf"     -out "$ca_dir/ca-cert.pem"
cat "$ca_dir/ca-cert.pem" "$ca_dir/root-cert.pem" > "$ca_dir/cert-chain.pem"
openssl verify -CAfile "$ca_dir/root-cert.pem" "$ca_dir/ca-cert.pem"
