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
workers="${TEST_WORKERS:-5}"
if [[ ! "$workers" =~ ^[1-5]$ ]]; then
  echo "Error: TEST_WORKERS debe ser un entero de 1 a 5 (por defecto 5)." >&2
  exit 1
fi
screenshots="${UI_TEST_SCREENSHOTS:-0}"
if [[ ! "$screenshots" =~ ^[01]$ ]]; then
  echo "Error: UI_TEST_SCREENSHOTS debe ser 0 o 1 (por defecto 0)." >&2
  exit 1
fi
results="$PWD/DerivedData/TestResults/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$results"
common=(-project PlantCareAI.xcodeproj -scheme PlantCareAI -destination "$destination" -derivedDataPath "$PWD/DerivedData")
# Compile app and both test bundles once; subsequent phases reuse those products.
xcodebuild "${common[@]}" build-for-testing
# Custom scheme variables are not expanded from arbitrary CLI build settings.
# Set the explicit runner environment once and use that exact configuration.
test_run=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" "$screenshots")
test_common=(-xctestrun "$test_run" -destination "$destination")
# XCTest owns the workers/clones. Do not start competing xcodebuild sessions.
# The system Photos test needs media on a known simulator, so it runs separately.
xcodebuild "${test_common[@]}" -parallel-testing-enabled YES -parallel-testing-worker-count "$workers" -maximum-concurrent-test-simulator-destinations "$workers" -skip-testing:PlantCareAIUITests/SystemGalleryUITests -resultBundlePath "$results/parallel.xcresult" test-without-building
# Seed distinguishable synthetic images only for the serial PhotosPicker test.
xcrun swift scripts/seed-identification-photos.swift "$PWD/DerivedData/IdentificationPhotoMedia"
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b
xcrun simctl addmedia "$udid" "$PWD/DerivedData/IdentificationPhotoMedia/picker-A.png" "$PWD/DerivedData/IdentificationPhotoMedia/picker-B.png"
xcodebuild "${test_common[@]}" -parallel-testing-enabled NO -only-testing:PlantCareAIUITests/SystemGalleryUITests -resultBundlePath "$results/gallery.xcresult" test-without-building
echo "Build y tests correctos. Resultados: $results (parallel.xcresult + gallery.xcresult). Apertura visual: abrir PlantCareAI.xcodeproj en Xcode."
