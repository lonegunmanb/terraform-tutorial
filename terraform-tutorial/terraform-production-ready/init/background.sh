#!/bin/bash
exec > /tmp/background.log 2>&1
set -x

source /root/setup-common.sh

# ── 1. Install tools ──────────────────────────────────────────────────────────
install_terraform
install_awscli

# ── 2. Start MiniStack ────────────────────────────────────────────────────────
start_localstack

# ── 3. Build step3 from step2 as base, then overlay step3-specific files ─────
# Killercoda already placed step3-specific files (storage module using
# terraform-aws-modules). Now fill in the remaining files from step2.
for f in $(find /root/workspace/step2 -type f); do
  relpath="${f#/root/workspace/step2/}"
  dest="/root/workspace/step3/${relpath}"
  if [ ! -f "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
  fi
done

# ── 4. Build step4 from step3 as base, then overlay step4-specific files ─────
# Killercoda already placed step4-specific files (validations, preconditions,
# postconditions, updated required_version). Fill in the rest from step3.
for f in $(find /root/workspace/step3 -type f); do
  relpath="${f#/root/workspace/step3/}"
  dest="/root/workspace/step4/${relpath}"
  if [ ! -f "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
  fi
done

# ── 5. Pre-init workspaces (speeds up student experience) ────────────────────
cd /root/workspace/step1
terraform init -input=false

cd /root/workspace/step2
terraform init -input=false

cd /root/workspace/step3
terraform init -input=false

cd /root/workspace/step4
terraform init -input=false

# ── 6. Signal setup complete ──────────────────────────────────────────────────
finish_setup
