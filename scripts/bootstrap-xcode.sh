#!/bin/sh
set -eu
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is required. Install it on the Mac used for development."
  exit 1
fi
cd "$(dirname "$0")/.."
xcodegen generate
echo "Generated GentleNote.xcodeproj"
