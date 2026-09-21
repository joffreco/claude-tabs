#!/usr/bin/env bash
# Removes claude-tabs from the system. The repository and the Claude
# transcripts are left alone.
set -euo pipefail

bin="$HOME/.local/bin"
conf="$HOME/.config/claude-tabs"
units="$HOME/.config/systemd/user"

if [ -d /run/systemd/system ]; then
  systemctl --user disable --now claude-tabs.service claude-tabs-ttyd.service 2>/dev/null || true
else
  pkill -f '^[^ ]*python3 [^ ]*claude-tabs-front$' || true
  pkill -f '^[^ ]*ttyd( .*)? [^ ]*claude-tabs-session$' || true
fi

tmux -L claude-tabs kill-server 2>/dev/null || true
rm -f "$bin"/claude-tabs "$bin"/claude-tabs-front "$bin"/claude-tabs-session "$bin"/claude-tabs-run
rm -f "$conf/tmux.conf" "$conf/env" "$units/claude-tabs.service" "$units/claude-tabs-ttyd.service"
rmdir "$conf" 2>/dev/null || true
systemctl --user daemon-reload 2>/dev/null || true

echo "claude-tabs is uninstalled. Transcripts under ~/.claude/projects were left untouched."
