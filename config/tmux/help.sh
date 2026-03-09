#!/bin/bash
cat <<'EOF'

  TMUX CHEATSHEET
  prefix = Ctrl+Space
  ─────────────────────────────────────────────────────────

  SESSIONS
  ──────────────────────────────────────────────────────────
  tmux                      Start new session
  tmux new -s name          Start named session
  tmux ls                   List sessions
  tmux a -t name            Attach to session
  prefix  $                 Rename current session
  prefix  s                 Switch / list sessions
  prefix  d                 Detach (leave session running)

  WINDOWS  (tabs)
  ──────────────────────────────────────────────────────────
  prefix  c                 New window
  prefix  ,                 Rename window
  prefix  n                 Next window
  prefix  p                 Previous window
  prefix  1-9               Jump to window by number
  prefix  &                 Kill window

  PANES  (splits)
  ──────────────────────────────────────────────────────────
  prefix  |                 Split vertically (side by side)
  prefix  -                 Split horizontally (top/bottom)
  prefix  h/j/k/l           Navigate panes (vim-style)
  prefix  H/J/K/L           Resize pane (hold prefix + repeat)
  prefix  z                 Zoom pane (fullscreen toggle)
  prefix  x                 Kill pane

  COPY MODE
  ──────────────────────────────────────────────────────────
  prefix  [                 Enter copy mode
  v                         Start selection
  y                         Copy selection and exit
  q  or  Escape             Exit copy mode

  OTHER
  ──────────────────────────────────────────────────────────
  prefix  r                 Reload config
  prefix  ?                 Show this cheatsheet
  prefix  I                 Install plugins (first time)

  ─────────────────────────────────────────────────────────
  Press  q  to close

EOF
