if status is-interactive
    alias ls="lsd"
    alias ll="lsd -l"
    alias la="lsd -la"
    alias lt="lsd --tree"

    fzf --fish | source
    zoxide init fish | source
end
