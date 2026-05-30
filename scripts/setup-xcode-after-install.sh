#!/bin/bash
# Run once after Xcode finishes installing from the App Store.
set -euo pipefail

if [[ ! -d /Applications/Xcode.app ]]; then
  echo "Xcode.app not found. Install Xcode from the App Store first."
  exit 1
fi

sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

export PATH="$HOME/.local/bin:$HOME/.gem/ruby/2.6.0/bin:$PATH"
pod --version

cd "$(dirname "$0")/.."
flutter doctor

echo "Done. iOS toolchain should show green in flutter doctor."
