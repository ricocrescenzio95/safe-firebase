#!/bin/bash

pid_file="/tmp/firebase-emulator.pid"

if [[ ! -f "$pid_file" ]]; then
  echo "Firestore Emulator PID file not found; nothing to stop."
  exit 0
fi

emulator_pid="$(cat "$pid_file")"

if [[ -n "$emulator_pid" ]] && kill -0 "$emulator_pid" 2>/dev/null; then
  kill "$emulator_pid" 2>/dev/null || true
  echo "Stopped Firestore Emulator (PID=$emulator_pid)."
else
  echo "Firestore Emulator is not running (PID=$emulator_pid)."
fi

rm -f "$pid_file"
