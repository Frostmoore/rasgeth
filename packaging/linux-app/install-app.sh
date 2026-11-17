#!/bin/sh
# RGCompanion for Linux (G40.12): installs the app from this folder for this user only, with an
# entry in the desktop's menu. Nothing outside the user's home, no administrator.
#
#   ./install-app.sh              install (or update) into ~/.local/share/rgcompanion
#   ./install-app.sh --uninstall  remove it (the RedGiants it knows stay in its settings)
#
# The app signs in like on a phone: the address (http://127.0.0.1:7600 for a RedGiant in Docker on
# this computer) and the password. A RedGiant installed with Docker (install.sh) is also always
# usable from the browser; the app is something more, never needed.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}
dest="$data/rgcompanion"
entry="$data/applications/rgcompanion.desktop"
icon="$data/icons/hicolor/512x512/apps/rgcompanion.png"

if [ "${1:-}" = "--uninstall" ]; then
  rm -rf "$dest" "$entry" "$icon"
  echo "RGCompanion removed."
  exit 0
fi
[ -x "$here/bundle/rgcompanion" ] || { echo "No bundle/rgcompanion next to this script." >&2; exit 1; }
# The Canvas's editors, widgets and «All settings» run in WebKitGTK (G42.0): the app needs it.
if command -v ldconfig >/dev/null 2>&1 && ! ldconfig -p 2>/dev/null | grep -q 'libwebkit2gtk-4.1'; then
  echo "RGCompanion needs WebKitGTK 4.1. Install it first, then run this again:" >&2
  echo "  Debian, Ubuntu: sudo apt install libwebkit2gtk-4.1-0" >&2
  echo "  Fedora:         sudo dnf install webkit2gtk4.1" >&2
  echo "  Arch:           sudo pacman -S webkit2gtk-4.1" >&2
  exit 1
fi
rm -rf "$dest.new"
mkdir -p "$dest.new" "$data/applications" "$(dirname "$icon")"
cp -R "$here/bundle/." "$dest.new/"
rm -rf "$dest"
mv "$dest.new" "$dest"
cp "$here/rgcompanion.png" "$icon"
sed "s|@EXEC@|$dest/rgcompanion|" "$here/rgcompanion.desktop" > "$entry"
chmod 644 "$entry"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$data/applications" >/dev/null 2>&1 || true
echo "RGCompanion installed: $dest (in the menu as RGCompanion)."
