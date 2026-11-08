#!/bin/bash
# 让 iStoreOS 固件默认启用 rknpu：/etc/init.d/kmods 只会把出现在
# kmods.kmods.enable 里的模块从 blacklist 中放行，否则开机就 blacklist rknpu。
set -euo pipefail

TARGET="package/diy/dkml/files/kmods.config"

python3 - "$TARGET" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

if "enable 'rknpu'" in text:
    print("[skip] rknpu already enabled in", path)
else:
    marker = "config global 'kmods'"
    if marker not in text:
        raise SystemExit("[fail] marker not found in %s" % path)
    text = text.replace(marker, marker + "\n\tlist enable 'rknpu'", 1)
    path.write_text(text, encoding="utf-8")
    print("[ok] enabled rknpu in", path)

print("--- head of %s ---" % path)
for line in path.read_text(encoding="utf-8").splitlines()[:5]:
    print(line)
PY
