if status is-interactive
    if type -q lsd
        alias ls="lsd --almost-all --long"
        alias lt="lsd --tree"
    end

    if type -q zoxide
        zoxide init fish | source
    end

    if type -q fzf
        set -Ux FZF_DEFAULT_OPTS "\
        --color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
        --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
        --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
        --color=selected-bg:#494D64 \
        --color=border:#6E738D,label:#CAD3F5"

        fzf --fish | source
    end
end
