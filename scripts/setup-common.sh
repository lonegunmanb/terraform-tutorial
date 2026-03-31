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

install_terraform() {
  apt-get update -qq && apt-get install -y -qq unzip > /dev/null 2>&1

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

install_awscli() {
  curl --connect-timeout 10 --max-time 120 -fsSL \
    "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o /tmp/awscliv2.zip \
    && unzip -o -q /tmp/awscliv2.zip -d /tmp/ \
    && /tmp/aws/install --update > /dev/null 2>&1 \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

  # Create awslocal wrapper (equivalent to awscli-local package)
  cat > /usr/local/bin/awslocal <<'WRAPPER'
#!/bin/bash
exec aws --endpoint-url=http://localhost:4566 "$@"
WRAPPER
  chmod +x /usr/local/bin/awslocal

  aws --version || echo "WARNING: awscli install failed"
}

start_localstack() {
  cd /root/workspace

  # Ensure Docker Compose v2 plugin is available
  if ! docker compose version > /dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq docker-compose-plugin > /dev/null 2>&1 \
      || {
        # Fallback: install plugin binary directly
        mkdir -p /usr/local/lib/docker/cli-plugins
        curl --connect-timeout 10 --max-time 120 -fsSL \
          "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
          -o /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
      }
  fi

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

finish_setup() {
  touch /tmp/.setup-done
}
