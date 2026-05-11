#!/bin/bash
# ─────────────────────────────────────────────────────────
# setup-common.sh — shared setup functions for Killercoda scenarios
#
# This file is the SINGLE SOURCE OF TRUTH for common setup logic.
# It is copied into each scenario's assets/ directory by:
#   npm run sync-setup  (or automatically via prebuild)
#
# Usage in background.sh:
#   source /root/setup-common.sh
#   install_terraform
#   install_awscli        # optional — AWS CLI v2 + awslocal wrapper
#   install_tflint        # optional — only in scenarios that need it
#   start_localstack
#   install_theia_plugin
#   finish_setup
# ─────────────────────────────────────────────────────────

TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.14.8}"
TFLINT_VERSION="${TFLINT_VERSION:-v0.61.0}"
TERRAGRUNT_VERSION="${TERRAGRUNT_VERSION:-0.77.5}"
MINIBLUE_VERSION="${MINIBLUE_VERSION:-0.7.0}"

install_terraform() {
  if ! command -v unzip > /dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq unzip > /dev/null 2>&1
  fi

  # Install Docker Compose v2 plugin (binary download — apt package not available on Killercoda)
  if ! docker compose version > /dev/null 2>&1; then
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl --connect-timeout 10 --max-time 120 -fsSL \
      "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  fi

  curl --connect-timeout 10 --max-time 120 -fsSL \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    -o /tmp/terraform.zip \
    && unzip -o -q /tmp/terraform.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform \
    && rm -f /tmp/terraform.zip

  terraform version || echo "WARNING: terraform install failed"
}

install_tflint() {
  curl --connect-timeout 10 --max-time 120 -fsSL \
    "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip" \
    -o /tmp/tflint.zip \
    && unzip -o -q /tmp/tflint.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/tflint \
    && rm -f /tmp/tflint.zip

  tflint --version || echo "WARNING: tflint install failed"
}

install_terragrunt() {
  curl --connect-timeout 10 --max-time 120 -fsSL \
    "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" \
    -o /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt

  terragrunt --version || echo "WARNING: terragrunt install failed"
}

install_awscli() {
  # Install AWS CLI v2 (official binary)
  curl --connect-timeout 10 --max-time 120 -fsSL \
    "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o /tmp/awscliv2.zip \
    && unzip -o -q /tmp/awscliv2.zip -d /tmp/ \
    && /tmp/aws/install --update > /dev/null 2>&1 \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

  aws --version || echo "WARNING: awscli install failed"

  # Disable AWS CLI pager globally so output prints directly
  mkdir -p /root/.aws
  cat > /root/.aws/config <<'AWSCFG'
[default]
region = us-east-1
output = json
cli_pager =
AWSCFG

  # Install awscli-local (provides the 'awslocal' command)
  pip3 install --break-system-packages awscli-local > /dev/null 2>&1 \
    || {
      # Fallback: create a shell wrapper if pip fails
      cat > /usr/local/bin/awslocal <<'WRAPPER'
#!/bin/bash
export AWS_PAGER=""
exec aws --endpoint-url=http://localhost:4566 --region us-east-1 "$@"
WRAPPER
      chmod +x /usr/local/bin/awslocal
    }

  awslocal --version || echo "WARNING: awslocal install failed"
}

start_localstack() {
  cd /root/workspace
  docker compose up -d

  echo "Waiting for LocalStack to be ready..."
  for i in $(seq 1 60); do
    if curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; then
      echo "LocalStack is ready."
      return 0
    fi
    sleep 2
  done
  echo "WARNING: LocalStack did not become healthy within 120 seconds"
  docker compose logs
}

start_miniblue() {
  cd /root/workspace
  mkdir -p /root/.miniblue
  docker compose up -d

  echo "Waiting for miniblue to be ready..."
  for i in $(seq 1 60); do
    if curl -sf http://localhost:4566/health > /dev/null 2>&1; then
      echo "miniblue is ready."
      # Trigger an HTTPS request so miniblue generates its self-signed cert.
      curl -sk https://localhost:4567/health > /dev/null 2>&1 || true

      # Locate cert inside the container and copy to host.
      # The miniblue image is distroless (no shell), so we can't `docker exec`
      # to probe — `docker cp` itself is sufficient and silently fails on
      # missing paths. Try known paths in order.
      local cid
      cid=$(docker compose ps -q miniblue 2>/dev/null)
      for j in $(seq 1 30); do
        if [ -n "$cid" ]; then
          for p in /home/nonroot/.miniblue/cert.pem /root/.miniblue/cert.pem /app/.miniblue/cert.pem; do
            if docker cp "$cid:$p" /root/.miniblue/cert.pem 2>/dev/null; then
              break 2
            fi
          done
        fi
        sleep 1
      done

      if [ ! -f /root/.miniblue/cert.pem ]; then
        echo "WARNING: failed to copy miniblue cert.pem out of container"
      else
        chmod 644 /root/.miniblue/cert.pem
      fi

      # Make SSL_CERT_FILE available for all interactive shells
      cat > /etc/profile.d/miniblue.sh <<'PROF'
export SSL_CERT_FILE=/root/.miniblue/cert.pem
PROF
      chmod +x /etc/profile.d/miniblue.sh
      # Killercoda terminals are non-login interactive shells — they only source
      # ~/.bashrc, not /etc/profile.d/*. Append the export there too (idempotent).
      if ! grep -q 'SSL_CERT_FILE=/root/.miniblue/cert.pem' /root/.bashrc 2>/dev/null; then
        echo 'export SSL_CERT_FILE=/root/.miniblue/cert.pem' >> /root/.bashrc
      fi
      export SSL_CERT_FILE=/root/.miniblue/cert.pem
      return 0
    fi
    sleep 2
  done
  echo "WARNING: miniblue did not become healthy within 120 seconds"
  docker compose logs
}

finish_setup() {
  touch /tmp/.setup-done
}
