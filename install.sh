#!/usr/bin/env bash
# Installs claude-tabs: the scripts are symlinked from this repository, the
# systemd units are copied. Run it again after editing a unit.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$HOME/.local/bin"
conf="$HOME/.config/claude-tabs"
units="$HOME/.config/systemd/user"
env_file="$conf/env"

missing=()
for tool in ttyd tmux python3 claude; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing tools: ${missing[*]}" >&2
  echo "On Debian or Ubuntu: sudo apt install ttyd tmux python3" >&2
  exit 1
fi

mkdir -p "$bin" "$conf" "$units"

# Where the sessions run. Claude keeps one transcript directory per working
# directory, so this also decides which conversations /resume lists.
current=""
[ -f "$env_file" ] && current=$(sed -n 's/^CLAUDE_TABS_DIR=//p' "$env_file" | tail -n 1)
default="${current:-$HOME}"
workdir="$default"
if [ -t 0 ]; then
  read -rp "Working directory for Claude sessions [$default]: " answer
  [ -n "$answer" ] && workdir="$answer"
fi
workdir="${workdir/#\~/$HOME}"
workdir="$(cd "$workdir" 2>/dev/null && pwd)" || { echo "No such directory: $workdir" >&2; exit 1; }
printf 'CLAUDE_TABS_DIR=%s\n' "$workdir" >"$env_file"

for script in claude-tabs claude-tabs-front claude-tabs-session claude-tabs-run; do
  chmod +x "$root/bin/$script"
  ln -sfn "$root/bin/$script" "$bin/$script"
done
ln -sfn "$root/config/tmux.conf" "$conf/tmux.conf"
install -m 644 "$root/systemd/claude-tabs.service" "$root/systemd/claude-tabs-ttyd.service" "$units/"

echo "Scripts linked into $bin, units copied into $units."
echo "Sessions will run in $workdir."

if [ -d /run/systemd/system ]; then
  systemctl --user daemon-reload
  echo
  echo "systemd is running. To start the stack with your session:"
  echo "    systemctl --user enable --now claude-tabs-ttyd.service claude-tabs.service"
  echo "    loginctl enable-linger \"$USER\"   # start it without opening a terminal"
else
  echo
  echo "systemd is not running in this distribution."
  echo "On WSL, add these two lines to /etc/wsl.conf, then run 'wsl --shutdown' from PowerShell:"
  echo "    [boot]"
  echo "    systemd=true"
  echo "Until then, 'claude-tabs start' runs the processes in the background."
fi

case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo; echo "Add $bin to your PATH to call claude-tabs directly." ;;
esac
