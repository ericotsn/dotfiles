#!/usr/bin/env bash

if ! command -v fish >/dev/null 2>&1; then
  print_error 'Fish shell is not installed'
  return 1
fi

local fish_path
fish_path="$(command -v fish)"

if ! grep -q "${fish_path}" /etc/shells; then
  print_info "Appending ${fish_path} to /etc/shells..."
  echo "${fish_path}" | sudo tee -a /etc/shells >/dev/null
fi

if [[ "${SHELL}" != "${fish_path}" ]]; then
  if chsh -s "${fish_path}"; then
    print_success 'Default shell changed to Fish'
  else
    print_error 'Failed to change default shell'
    return 1
  fi
else
  print_success 'Fish is already the default shell'
fi
