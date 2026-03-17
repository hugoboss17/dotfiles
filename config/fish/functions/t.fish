function t --description "Open or attach to a tmux session named after the current directory"
    set session (basename (pwd))

    if tmux has-session -t $session 2>/dev/null
        tmux attach -t $session
    else
        tmux new-session -s $session
    end
end
