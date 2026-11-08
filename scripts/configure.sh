#!/bin/bash
# 生成并校验 .config：必须选中 R76S 设备、kmod-rknpu、LuCI。
set -euo pipefail

cd "$(dirname "$0")/.."
cp configs/r76s.fragment openwrt/.config
cd openwrt

make defconfig

required=(
  "CONFIG_TARGET_rockchip=y"
  "CONFIG_TARGET_rockchip_armv8=y"
  "CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r76s=y"
  "CONFIG_PACKAGE_kmod-rknpu=y"
  "CONFIG_PACKAGE_luci=y"
)

missing=0
for key in "${required[@]}"; do
  if grep -q "^${key}$" .config; then
    echo "[ok] $key"
  else
    echo "[missing] $key"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "=== tail of .config ==="
  tail -40 .config
  exit 1
fi

echo "=== rknpu / kmod 相关配置 ==="
grep -E "kmod-rknpu|rockchip-system-monitor|^CONFIG_PACKAGE_kmod-drm" .config || true
