#!/usr/bin/env bash

if command -v 1password >/dev/null 2>&1; then
  print_success '1Password is already installed'
  return 0
fi

print_info 'Installing 1Password GPG key...'
sudo mkdir -p /etc/pki/rpm-gpg
curl -fsSL 'https://downloads.1password.com/linux/keys/1password.asc' | sudo gpg --dearmor -o /etc/pki/rpm-gpg/1password.gpg

print_info 'Installing 1Password repository configuration...'
sudo tee /etc/yum.repos.d/1password.repo >/dev/null <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/1password.gpg
EOF

sudo dnf install -y 1password 1password-cli

print_success '1Password installed successfully'
