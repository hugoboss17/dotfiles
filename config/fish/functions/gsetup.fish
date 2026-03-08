function gsetup
    set dotfiles $HOME/Projects/dotfiles

    if test (count $argv) -eq 0
        echo "Usage: gsetup <command>"
        echo ""
        echo "Commands:"
        echo "  pr-description   Add AI-generated PR description workflow"
        echo "  phaser-ci        Add Phaser CI workflow (TypeScript check + build)"
        echo "  android-release  Add Android signed AAB release workflow"
        echo "  laravel-ci       Add Laravel CI workflow (Pint + PHPStan + Pest)"
        return 0
    end

    if not test -d (pwd)/.git
        echo "Not a git repository."
        return 1
    end

    set workflows_dir (pwd)/.github/workflows

    switch $argv[1]
        case pr-description
            _gsetup_copy "$dotfiles/templates/github/workflows/pr-description.yml" "$workflows_dir/pr-description.yml"
        case phaser-ci
            _gsetup_copy "$dotfiles/templates/github/workflows/phaser-ci.yml" "$workflows_dir/ci.yml"
        case android-release
            _gsetup_copy "$dotfiles/templates/github/workflows/android-release.yml" "$workflows_dir/android-release.yml"
        case laravel-ci
            _gsetup_copy "$dotfiles/templates/github/workflows/laravel-ci.yml" "$workflows_dir/ci.yml"
        case '*'
            echo "Unknown command: $argv[1]"
            echo "Run 'gsetup' with no arguments to see available commands."
            return 1
    end
end

function _gsetup_copy
    set src $argv[1]
    set dest $argv[2]
    mkdir -p (dirname $dest)
    if test -f $dest
        echo "Already exists: $dest"
        return 0
    end
    cp $src $dest
    echo "Added: $dest"
end
