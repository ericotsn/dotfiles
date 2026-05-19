#!/usr/bin/env bash

if ! command -v fc-list >/dev/null 2>&1; then
  print_error 'fc-list (fontconfig) is not installed'
  return 1
fi

if fc-list --quiet 'PragmataPro'; then
  print_success 'PragmataPro font is already installed'
  return 0
fi

local font_temp_dir
font_temp_dir=$(mktemp -d)
local font_install_dir="${HOME}/Library/Fonts"

print_info 'Cloning font repository...'
if git clone git@github.com:ericotsn/pragmatapro.git "${font_temp_dir}"; then
  print_success 'Repository cloned successfully'
else
  print_error 'Failed to clone font repository'
  rm -rf "${font_temp_dir}"
  return 1
fi

mkdir -p "${font_install_dir}"
print_info 'Installing font files...'

local font_count=0
while IFS= read -r -d '' font_file; do
  cp "${font_file}" "${font_install_dir}/"
  ((++font_count))
done < <(find "${font_temp_dir}" -type f \( -name '*.otf' -o -name '*.ttf' \) -print0)

if [[ ${font_count} -gt 0 ]]; then
  print_success "Installed ${font_count} font files"
else
  print_warning 'No font files found in repository'
fi

rm -rf "${font_temp_dir}"
