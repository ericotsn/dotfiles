set -gx PNPM_HOME ~/.local/share/pnpm

if test -d "$PNPM_HOME"
  fish_add_path -g "$PNPM_HOME/bin"
end
