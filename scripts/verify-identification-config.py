#!/usr/bin/env python3
"""Compare a locally entered key to the built Debug Info.plist without printing either.
Run only on private local artifacts. Do not pass the key in arguments or environment.
"""
import argparse
import getpass
import math
import plistlib
from urllib.parse import urlsplit, urlunsplit
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("app", type=Path)
mode = parser.add_mutually_exclusive_group()
mode.add_argument("--release", action="store_true")
mode.add_argument("--empty-template", action="store_true", help="Check a test build with no key, without making a request")
args = parser.parse_args()
with (args.app / "Info.plist").open("rb") as source:
    info = plistlib.load(source)
keys = {"PlantCareAIAPIScheme", "PlantCareAIAPIHostPath", "PlantCareAIModel", "PlantCareAIAPIKey", "PlantCareAITimeoutSeconds", "PlantCareAIBaseURL"}
if args.release:
    if keys.intersection(info):
        raise SystemExit("FAIL: Release contains identification configuration entries")
    binary = (args.app / "PlantCareAI").read_bytes()
    if any(value in binary for value in [b"--identification-candidates-fixture", b"IdentificationCandidatesTestFixture", b"--consent-spy"]):
        raise SystemExit("FAIL: Release contains test seams")
    print("OK: Release has no configuration entries or identification/consent test seams")
else:
    def canonical_base(value):
        try:
            if not isinstance(value, str) or len(value) > 2048 or any(c.isspace() or ord(c) < 32 for c in value) or "?" in value or "#" in value:
                raise ValueError()
            parts = urlsplit(value)
            if parts.scheme != "https" or not parts.hostname or parts.username is not None or parts.password is not None:
                raise ValueError()
            if "%" in parts.hostname or "%" in parts.path or "//" in parts.path or any(p in (".", "..") for p in parts.path.split("/")):
                raise ValueError()
            port = parts.port
            if port is not None and not 1 <= port <= 65535:
                raise ValueError()
            path = parts.path[:-1] if parts.path.endswith("/") else parts.path
            if path.lower().endswith("/chat/completions"):
                raise ValueError()
            host = parts.hostname.lower()
            if ":" in host:
                host = "[" + host + "]"
            authority = host + (":" + str(port) if port not in (None, 443) else "")
            return urlunsplit(("https", authority, path, "", ""))
        except ValueError:
            raise SystemExit("FAIL: invalid HTTPS base URL; no values logged")

    scheme = info.get("PlantCareAIAPIScheme")
    host_path = info.get("PlantCareAIAPIHostPath")
    model = info.get("PlantCareAIModel")
    if scheme != "https" or not isinstance(host_path, str) or host_path.startswith("/") or "://" in host_path or "//" in host_path:
        raise SystemExit("FAIL: invalid scheme/host-path")
    canonical = canonical_base(scheme + "://" + host_path)
    if not isinstance(model, str) or not model or len(model) > 160 or model != model.strip() or any(ord(c) < 32 or ord(c) == 127 for c in model) or model.startswith("$("):
        raise SystemExit("FAIL: invalid model")
    try:
        timeout = info.get("PlantCareAITimeoutSeconds")
        seconds = 60 if timeout in (None, "") else float(timeout)
        if not math.isfinite(seconds) or not 10 <= seconds <= 120:
            raise ValueError()
    except (ValueError, TypeError):
        raise SystemExit("FAIL: invalid timeout")
    actual = info.get("PlantCareAIAPIKey") or ""
    if not isinstance(actual, str) or (actual.strip() and (actual != actual.strip() or any(not 33 <= ord(c) <= 126 for c in actual) or actual.startswith("$(") or actual.lower() in {"placeholder", "your-key", "your_api_key", "replace-me", "example-key", "<key>", "<api_key>"})):
        raise SystemExit("FAIL: invalid key representation; no values logged")
    if args.empty_template:
        if info.get("PlantCareAIAPIKey"):
            raise SystemExit("FAIL: template build contains a nonempty key")
    else:
        original_base = input("Original HTTPS API base URL (no credentials/query): ")
        original_model = input("Original API_MODEL: ")
        if canonical_base(original_base) != canonical or original_model != model:
            raise SystemExit("FAIL: destination/model not represented exactly; do not send a request")
        expected = getpass.getpass("Original API_KEY (hidden; blank if omitted): ")
        if (expected and expected != actual) or (not expected and actual.strip()):
            raise SystemExit("FAIL: key not represented exactly; do not send a request")
    if "PlantCareAIBaseURL" in info:
        raise SystemExit("FAIL: obsolete unsplit URL configuration entry present")
    if args.empty_template:
        print("OK: valid HTTPS destination/model and empty key; no Authorization, no request sent")
    else:
        print("OK: canonical destination/model and optional key roundtrip exact; no request sent")
