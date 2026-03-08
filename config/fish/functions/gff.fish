function gff
    gdevp && git merge feature/$argv[1] && git push && gmp && git merge feature/$argv[1] && git push
end
