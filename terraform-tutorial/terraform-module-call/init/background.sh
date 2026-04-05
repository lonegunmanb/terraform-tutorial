#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Install tools ──
install_terraform
install_awscli

# ── 2. Start LocalStack ──
start_localstack

# ── 3. Pre-init step1 to speed up student experience ──
cd /root/workspace/step1
terraform init

# ── 4. Signal completion ──
finish_setup
