#!/bin/bash
set -u

emulator_log="/tmp/firebase-emulator.log"
pid_file="/tmp/firebase-emulator.pid"

firebase_command=""
for node_bin in "$HOME"/.nvm/versions/node/*/bin; do
  candidate="$node_bin/firebase"
  if [[ -x "$candidate" ]]; then
    firebase_command="$candidate"
  fi
done

if [[ -z "$firebase_command" ]]; then
  for candidate in /opt/homebrew/bin/firebase /usr/local/bin/firebase; do
    if [[ -x "$candidate" ]]; then
      firebase_command="$candidate"
      break
    fi
  done
fi

if [[ -z "$firebase_command" ]]; then
  echo "Firebase CLI not found; install firebase-tools."
  exit 1
fi

export PATH="$(dirname "$firebase_command"):/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js not found; Firebase CLI cannot start."
  exit 1
fi

if [[ -z "${WORKSPACE_PATH:-}" ]]; then
  echo "WORKSPACE_PATH is not set in the Xcode pre-action."
  exit 1
fi

repo_root="$(cd "$(dirname "$WORKSPACE_PATH")/../.." && pwd)"
config="$repo_root/firebase.json"

if [[ ! -f "$config" ]]; then
  echo "firebase.json not found: $config"
  exit 1
fi

"$firebase_command" --config "$config" emulators:start \
  --only firestore --project demo-safe-firebase \
  > "$emulator_log" 2>&1 &
emulator_pid=$!
echo "$emulator_pid" > "$pid_file"

echo "Started Firestore Emulator (PID=$emulator_pid);"
