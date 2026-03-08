function gff
    if test (count $argv) -lt 1
        echo "Usage: gff <feature-name>"
        return 1
    end
    gdevp && git merge feature/$argv[1] && git push && gmp && git merge feature/$argv[1] && git push
end
