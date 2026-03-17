# Pentest toolkit
set -x PENTEST_TOOLKIT $HOME/Projects/pentest-toolkit
set -x CLIENT_REPORTS $HOME/client-reports

# fish PATH additions for security tools
fish_add_path /opt/homebrew/bin
fish_add_path $HOME/.local/bin    # pip3 --user installed tools (impacket, frida, etc.)

# ─── Aliases ───────────────────────────────────────────

# Lab management
alias lab-up="cd $PENTEST_TOOLKIT/lab && docker compose up -d"
alias lab-down="cd $PENTEST_TOOLKIT/lab && docker compose down"
alias lab-mobile="cd $PENTEST_TOOLKIT/lab && docker compose --profile mobile up -d"
alias lab-ad="cd $PENTEST_TOOLKIT/lab && docker compose --profile ad up -d"
alias lab-status="docker compose -f $PENTEST_TOOLKIT/lab/docker-compose.yml ps"

# Pentest workflow shortcuts
alias pt-init="$PENTEST_TOOLKIT/init.sh"
alias pt-recon="$PENTEST_TOOLKIT/recon.sh"
alias pt-web="$PENTEST_TOOLKIT/web-scan.sh"
alias pt-net="$PENTEST_TOOLKIT/network-scan.sh"
alias pt-mobile="$PENTEST_TOOLKIT/mobile-scan.sh"
alias pt-api="$PENTEST_TOOLKIT/api-scan.sh"
alias pt-cloud="$PENTEST_TOOLKIT/cloud-scan.sh"
alias pt-report="$PENTEST_TOOLKIT/report.sh"

# Quick navigation
alias client-reports="cd $CLIENT_REPORTS"
alias toolkit="cd $PENTEST_TOOLKIT"

# Tool shortcuts
alias msf="msfconsole -q"
alias bsuite="open -a 'Burp Suite Professional' 2>/dev/null || open -a 'Burp Suite Community Edition'"
