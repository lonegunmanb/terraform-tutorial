#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Install tools ──────────────────────────────────────────────────────────
install_terraform
install_awscli
install_terragrunt

# ── 2. Start MiniStack ────────────────────────────────────────────────────────
start_localstack

# ── 3. Pre-init workspace ────────────────────────────────────────────────────
cd /root/workspace
terraform init -input=false

# ── 4. Signal setup complete ──────────────────────────────────────────────────
finish_setup
