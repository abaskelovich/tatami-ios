#!/usr/bin/env bash
set -euo pipefail

# Print only a UDID; the workflow writes it to GITHUB_OUTPUT.
device_list="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/tatami-simulators.json"
xcrun simctl list devices available -j > "$device_list"
python3 - "$device_list" <<'PY'
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    devices = json.load(source)["devices"]

def runtime_version(runtime):
    match = re.search(r"\.iOS-(\d+(?:-\d+)*)$", runtime)
    return tuple(map(int, match.group(1).split("-"))) if match else ()

for runtime in sorted(devices, key=runtime_version, reverse=True):
    if not runtime_version(runtime):
        continue
    for device in sorted(devices[runtime], key=lambda item: item["name"]):
        if device.get("isAvailable", False) and device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("No available iPhone simulator found")
PY
