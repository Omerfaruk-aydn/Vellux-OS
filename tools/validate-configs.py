#!/usr/bin/env python3
"""Vellux OS yapilandirma dosyalarinin sozdizimini dogrular (CI + yerel)."""
import glob
import json
import re
import sys

try:
    import yaml
except ImportError:  # CI'da PyYAML hazir gelir; yerelde pip install pyyaml
    print("PyYAML gerekli: pip install pyyaml")
    sys.exit(2)

bad = 0
yaml_files = (
    glob.glob("core/overlay/etc/calamares/**/*.conf", recursive=True)
    + glob.glob("core/overlay/usr/share/calamares/branding/vellux/branding.desc")
    + glob.glob("core/overlay/etc/netplan/*.yaml")
)
for f in sorted(yaml_files):
    try:
        yaml.safe_load(open(f, encoding="utf-8"))
        print("ok  ", f)
    except Exception as exc:
        print("FAIL", f, exc)
        bad += 1

raw = open("shell/waybar/config.jsonc", encoding="utf-8").read()
raw = re.sub(r"^\s*//.*$", "", raw, flags=re.M)
try:
    json.loads(raw)
    print("ok   shell/waybar/config.jsonc")
except Exception as exc:
    print("FAIL shell/waybar/config.jsonc", exc)
    bad += 1

sys.exit(1 if bad else 0)
