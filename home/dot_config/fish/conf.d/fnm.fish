set FNM_PATH ~/.local/share/fnm

if test -d "$FNM_PATH"
  fish_add_path -g "$FNM_PATH"
end

fnm env --use-on-cd --log-level=quiet --shell fish | source
