set -x XDG_CONFIG_HOME "$HOME/.config"

if string match -q -- '*vscode*' $TERM_PROGRAM
  set -x VISUAL 'code --wait'
else
  set -x EDITOR 'nvim'
  set -x MANPAGER 'nvim +Man!'
end

fish_add_path -g ~/.local/bin ~/bin
