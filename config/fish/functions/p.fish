function p
    set project "$argv[1]"
    set project_dir "$HOME/Projects/$project"

    if test -d "$project_dir"
        cd "$project_dir"
    else
        echo "Project not found: $project"
    end
end