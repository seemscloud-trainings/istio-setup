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
for cluster in cluster1 cluster2; do
  mkdir -p "$ca_dir/$cluster"
  openssl req -new -newkey rsa:4096 -nodes     -keyout "$ca_dir/$cluster/ca-key.pem"     -out "$ca_dir/$cluster/ca.csr"     -subj "/O=Istio Training/CN=$cluster Intermediate CA"
  cat > "$ca_dir/$cluster/extensions.cnf" <<EOF
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
EOF
  openssl x509 -req -sha256 -days 1825     -in "$ca_dir/$cluster/ca.csr"     -CA "$ca_dir/root-cert.pem" -CAkey "$ca_dir/root-key.pem"     -CAserial "$ca_dir/root-cert.srl" -CAcreateserial     -extfile "$ca_dir/$cluster/extensions.cnf"     -out "$ca_dir/$cluster/ca-cert.pem"
  cp "$ca_dir/root-cert.pem" "$ca_dir/$cluster/root-cert.pem"
  cat "$ca_dir/$cluster/ca-cert.pem" "$ca_dir/root-cert.pem" > "$ca_dir/$cluster/cert-chain.pem"
  openssl verify -CAfile "$ca_dir/root-cert.pem" "$ca_dir/$cluster/ca-cert.pem"
done
