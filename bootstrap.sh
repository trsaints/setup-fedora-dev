#!/usr/bin/env bash
set -euo pipefail

if ! command -v ansible-playbook >/dev/null 2>&1; then
  sudo dnf install -y ansible-core
fi

ansible-playbook playbook.yml --ask-become-pass "$@"
