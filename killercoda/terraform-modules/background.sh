#!/bin/bash
set -e

# --- Install Terraform CLI ---
apt-get update -qq
apt-get install -y -qq gnupg software-properties-common curl > /dev/null 2>&1
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
apt-get update -qq
apt-get install -y -qq terraform > /dev/null 2>&1

# --- Start LocalStack via Docker Compose ---
cd /root/workspace
docker-compose up -d 2>&1

echo "Waiting for LocalStack to be ready..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "LocalStack is ready."
    break
  fi
  sleep 2
done

# --- Signal completion ---
touch /tmp/.setup-done
