#!/usr/bin/env python3
"""Set the capture opt-in in Xcode's generated test configuration, not app config."""

import argparse
import plistlib
from pathlib import Path


def set_capture_environment(value, screenshots):
    count = 0
    if isinstance(value, dict):
        for key, item in value.items():
            if key == "EnvironmentVariables" and isinstance(item, dict) and "UI_TEST_SCREENSHOTS" in item:
                item["UI_TEST_SCREENSHOTS"] = screenshots
                count += 1
            else:
                count += set_capture_environment(item, screenshots)
    elif isinstance(value, list):
        for item in value:
            count += set_capture_environment(item, screenshots)
    return count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("products", type=Path)
    parser.add_argument("screenshots", choices=("0", "1"))
    args = parser.parse_args()
    runs = list(args.products.glob("PlantCareAI_*.xctestrun"))
    if not runs:
        parser.error("No generated PlantCareAI xctestrun; run build-for-testing first")
    # build-for-testing refreshes this file even when compilation is incremental.
    run = max(runs, key=lambda path: path.stat().st_mtime_ns)
    configuration = plistlib.loads(run.read_bytes())
    if not set_capture_environment(configuration, args.screenshots):
        parser.error("No UI_TEST_SCREENSHOTS environment in the generated test configuration")
    run.write_bytes(plistlib.dumps(configuration, sort_keys=False))
    print(run.resolve())


if __name__ == "__main__":
    main()
