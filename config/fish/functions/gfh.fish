function gfh
    if test (count $argv) -lt 1
        echo "Usage: gfh <hotfix-name>"
        return 1
    end
    gdevp && git merge hotfix/$argv[1] && git push && gmp && git merge hotfix/$argv[1] && git push
end
