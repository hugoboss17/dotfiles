#!/bin/bash

ZPROFILE="$HOME/.zprofile"

if ! command -v php /dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://php.new/install/mac)"
fi

if [ -d "$HOME/.config/herd-lite/bin" ]; then
    SHELL_NAME=$(basename "${SHELL:-$(dscl . -read /Users/$USER UserShell 2>/dev/null | awk '{print $2}' || echo /bin/zsh)}")
    LINE_TO_ADD='export PATH="$HOME/.config/herd-lite/bin:$PATH"'

    if [ ! -f "$ZPROFILE" ] || ! grep -Fxq "$LINE_TO_ADD" "$ZPROFILE" 2>/dev/null; then
        printf "\n# Add herd-lite to PATH\n%s\n" "$LINE_TO_ADD" >> "$ZPROFILE"
    fi
fi
