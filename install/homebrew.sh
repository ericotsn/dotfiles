#!/usr/bin/env bash

if command -v brew >/dev/null 2>&1; then
  print_success 'Homebrew is already installed'
  return 0
fi

local log_file
log_file="$(mktemp)"

NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >"${log_file}" 2>&1
local exit_code=$?

if [[ $exit_code -eq 0 ]]; then
  print_success 'Homebrew installed successfully'
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  print_error "Homebrew installation failed (exit code: ${exit_code})"
  cat "${log_file}" >&2
fi

rm -f "${log_file}"
return ${exit_code}
