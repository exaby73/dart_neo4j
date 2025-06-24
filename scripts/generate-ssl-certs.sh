#!/bin/bash

# SSL Certificate Generation Script for Neo4j Testing
# This script generates self-signed certificates for testing SSL connections

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="$SCRIPT_DIR/../ssl-certs"

echo "🔐 Generating SSL certificates for Neo4j testing..."

# Create certificates directory
mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

# Clean up any existing certificates
rm -f *.pem *.key *.crt *.srl

echo "📝 Creating CA private key..."
openssl genrsa -out ca-key.pem 4096

echo "📝 Creating CA certificate..."
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca-cert.pem -subj "/C=US/ST=CA/L=Test/O=Neo4j Test/OU=Testing/CN=Neo4j Test CA"

echo "📝 Creating server private key..."
openssl genrsa -out server-key.pem 4096

echo "📝 Creating server certificate signing request..."
openssl req -subj "/C=US/ST=CA/L=Test/O=Neo4j Test/OU=Testing/CN=localhost" -sha256 -new -key server-key.pem -out server.csr

echo "📝 Creating server certificate extensions..."
cat > server-extensions.cnf << EOF
basicConstraints=CA:FALSE
keyUsage=nonRepudiation,digitalSignature,keyEncipherment
subjectAltName=@alt_names

[alt_names]
DNS.1=localhost
DNS.2=neo4j-single-ssl
DNS.3=neo4j-cluster-ssl-1
DNS.4=neo4j-cluster-ssl-2
DNS.5=neo4j-cluster-ssl-3
IP.1=127.0.0.1
IP.2=::1
EOF

echo "📝 Signing server certificate with CA..."
openssl x509 -req -days 365 -in server.csr -CA ca-cert.pem -CAkey ca-key.pem -out server-cert.pem -extfile server-extensions.cnf -CAcreateserial

echo "📝 Creating self-signed certificate configuration..."
cat > self-signed-extensions.cnf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]

[v3_req]
basicConstraints=CA:FALSE
keyUsage=nonRepudiation,digitalSignature,keyEncipherment
subjectAltName=@alt_names

[alt_names]
DNS.1=localhost
DNS.2=neo4j-self-signed
IP.1=127.0.0.1
IP.2=::1
EOF

echo "📝 Creating self-signed certificate for testing self-signed scenarios..."
openssl req -new -x509 -days 365 -key server-key.pem -sha256 -out self-signed-cert.pem -subj "/C=US/ST=CA/L=Test/O=Neo4j Test/OU=Testing/CN=localhost" -extensions v3_req -config self-signed-extensions.cnf

echo "📝 Setting appropriate permissions..."
chmod 600 ca-key.pem server-key.pem
chmod 644 ca-cert.pem server-cert.pem self-signed-cert.pem
chmod 644 server-extensions.cnf self-signed-extensions.cnf server.csr ca-cert.srl

echo "🔍 Certificate details:"
echo "CA Certificate:"
openssl x509 -in ca-cert.pem -text -noout | grep -E "(Subject:|Not Before|Not After)"
echo ""
echo "Server Certificate:"
openssl x509 -in server-cert.pem -text -noout | grep -E "(Subject:|Not Before|Not After|DNS:|IP Address)"
echo ""
echo "Self-signed Certificate:"
openssl x509 -in self-signed-cert.pem -text -noout | grep -E "(Subject:|Not Before|Not After|DNS:|IP Address)"

echo ""
echo "✅ SSL certificates generated successfully!"
echo "📁 Certificates location: $CERTS_DIR"
echo ""
echo "Generated files:"
echo "  - ca-cert.pem           (CA certificate for validation)"
echo "  - ca-key.pem            (CA private key)"
echo "  - server-cert.pem       (Server certificate signed by CA)"
echo "  - server-key.pem        (Server private key)"
echo "  - self-signed-cert.pem  (Self-signed certificate for +ssc testing)"
echo ""
echo "🚀 Ready to use with Docker Compose SSL Neo4j instances!"