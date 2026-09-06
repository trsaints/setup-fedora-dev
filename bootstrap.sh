#!/usr/bin/env bash
set -euo pipefail

mkdir -p logs
log_file="logs/ansible-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$log_file") 2>&1

printf 'Ansible stdout log: %s\n' "$log_file"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  sudo dnf install -y ansible-core
fi

ANSIBLE_FORCE_COLOR=false ansible-playbook playbook.yml --ask-become-pass "$@"
