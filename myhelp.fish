function myhelp
    if count $argv = 0
        cat ~/Projects/dotfiles/docs/myhelp/index
        exit 1
    end

    if test -e ~/Projects/dotfiles/docs/myhelp/$1
        cat ~/Projects/dotfiles/docs/myhelp/$1
    else
        echo "error: argument not found."
    end
end

