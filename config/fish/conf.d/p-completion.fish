<<<<<<< HEAD
complete -c p -f -a "(for d in $HOME/Projects/*; if test -d \$d; basename \$d; end; end)"
=======
complete -c p -a "(for d in $HOME/Projects/*; if test -d \$d; basename \$d; end)"
>>>>>>> main
