#!/usr/bin/env bash
set -euo pipefail

mkdir -p logs
log_file="logs/ansible-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$log_file") 2>&1

printf 'Ansible stdout log: %s\n' "$log_file"

sudo -k
sudo_password=""

cleanup() {
  local exit_code=$?

  if [[ -n "${sudo_keepalive_pid:-}" ]]; then
    kill "$sudo_keepalive_pid" 2>/dev/null || true
  fi

  exit "$exit_code"
}

trap cleanup EXIT

while true; do
  IFS= read -r -s -p "[sudo] senha para $USER: " sudo_password
  printf '\n'

  if printf '%s\n' "$sudo_password" | sudo -S -v -p '' 2>/dev/null; then
    break
  fi

  printf 'Senha sudo invalida. Tente novamente.\n' >&2
  sudo -k
done

while true; do
  sudo -n true
  sleep 60
done 2>/dev/null &
sudo_keepalive_pid=$!

if ! command -v ansible-playbook >/dev/null 2>&1; then
  sudo dnf install -y ansible-core
fi

ansible-galaxy collection install -r requirements.yml

ANSIBLE_BECOME_ASK_PASS=false \
  ANSIBLE_BECOME_PASS="$sudo_password" \
  ANSIBLE_FORCE_COLOR=false \
  ansible-playbook playbook.yml "$@"
