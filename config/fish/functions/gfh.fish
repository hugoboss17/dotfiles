function gfh
    gdevp && git merge hotfix/$argv[1] && git push && gmp && git merge hotfix/$argv[1] && git push
end
