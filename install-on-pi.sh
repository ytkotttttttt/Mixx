#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/nauticmixxx-pi-build.log"

if [[ "$(uname -m)" != "aarch64" ]] || [[ "$(getconf LONG_BIT)" != "64" ]]; then
  echo "ERROR: This installer targets 64-bit ARM Linux (aarch64)."; exit 1
fi
if ! command -v git >/dev/null; then
  echo "Installing Git..."; sudo apt-get update; sudo apt-get install -y git unzip
fi
sudo apt-get update
sudo apt-get install -y unzip

WORK="$HOME/NauticMixxx-build"
if [[ -d "$WORK/.git" ]]; then
  git -C "$WORK" pull --ff-only
else
  git clone https://github.com/nauticsoftware/NauticMixxx.git "$WORK"
fi
cd "$WORK"
chmod +x scripts/install-linux-build-deps.sh scripts/build-mixxx-rx3-linux.sh
./scripts/install-linux-build-deps.sh
# Conservative build setting for Pi 4 RAM and thermals.
RX3_BUILD_JOBS=1 ./scripts/build-mixxx-rx3-linux.sh 2>&1 | tee "$LOG"
BIN="$WORK/build/test-candidate/1.5.0-linux-$(uname -m)/stage/bin/nauticmixxx"
if [[ ! -x "$BIN" ]]; then echo "ERROR: Expected built binary not found: $BIN"; exit 1; fi
# Install bundled skin to the standard Mixxx skin location as a convenience.
SKINZIP="$HERE/NauticMixxx-2.0.0-skin.zip"
if [[ -f "$SKINZIP" ]]; then
  TMP="$(mktemp -d)"
  unzip -q "$SKINZIP" -d "$TMP"
  mkdir -p "$HOME/.mixxx/skins"
  rm -rf "$HOME/.mixxx/skins/XDJ_RX3_Mixxx"
  cp -a "$TMP/XDJ_RX3_Mixxx" "$HOME/.mixxx/skins/"
  rm -rf "$TMP"
fi
printf '\nBuild completed.\nExecutable: %s\nLog: %s\n' "$BIN" "$LOG"
echo "Launch with: $BIN"
"$BIN" --install-desktop || true
