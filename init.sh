#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodebuild >/dev/null 2>&1 || ! xcodebuild -version >/dev/null 2>&1; then
  echo "Error: instala Xcode y configúralo con xcode-select antes de ejecutar ./init.sh." >&2
  exit 1
fi
if ! command -v xcrun >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  echo "Error: hacen falta xcrun (Xcode) y python3 para seleccionar un simulador iPhone." >&2
  exit 1
fi

if ! devices=$(xcrun simctl list devices available --json); then
  echo "Error: configura un runtime y simulador iPhone en Xcode (Settings > Platforms)." >&2
  exit 1
fi
if ! udid=$(printf '%s' "$devices" | python3 -c '
import json, sys
devices = [d for group in json.load(sys.stdin)["devices"].values() for d in group
           if d.get("isAvailable") and "iPhone" in d.get("deviceTypeIdentifier", "")]
devices.sort(key=lambda d: d.get("state") != "Booted")
if devices: print(devices[0]["udid"])
'); then
  echo "Error: no se pudo leer la lista de simuladores; comprueba Xcode y sus runtimes." >&2
  exit 1
fi
if [[ -z "$udid" ]]; then
  echo "Error: no hay simulador iPhone disponible; instala un runtime iOS y crea un iPhone en Xcode." >&2
  exit 1
fi

echo "Destino iPhone Simulator: $udid"
destination="platform=iOS Simulator,id=$udid"
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination "$destination" -derivedDataPath "$PWD/DerivedData" build
# Seed distinguishable local images for the real PhotosPicker UI test, outside the app.
# They contain no user data and remain in ignored DerivedData / simulator Photos.
xcrun swift scripts/seed-identification-photos.swift "$PWD/DerivedData/IdentificationPhotoMedia"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b
xcrun simctl addmedia "$udid" "$PWD/DerivedData/IdentificationPhotoMedia/picker-A.png" "$PWD/DerivedData/IdentificationPhotoMedia/picker-B.png"
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination "$destination" -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO test
echo "Build y tests correctos. Apertura visual: instalar DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app y lanzar org.plantcareai.prototype con simctl, o abrir PlantCareAI.xcodeproj en Xcode."
