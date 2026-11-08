# iStoreOS for NanoPi R76S，默认启用 rknpu

在 GitHub 托管的 runner 上编译 iStoreOS（rockchip/armv8）给 FriendlyElec NanoPi R76S，
并让 Rockchip NPU 驱动（`kmod-rknpu`）开机默认加载。

## 为什么要这份 CI

目标板子上 `kmod-rknpu` 已存在，但开机被 `/etc/init.d/kmods` 写入 blacklist；把它放行后手动
`insmod` 会让内核 panic：

```
rockchip-pm-domain ...: failed to get ack on domain 'nputop', val=0x11bff
Kernel panic - not syncing: Asynchronous SError Interrupt
  regmap_write -> rockchip_pmu_restore_qos -> rockchip_pd_power -> genpd_power_on -> (rknpu probe)
```

板子上那颗驱动是 `rknpu 0.9.8 20240828`（内核 6.6）。本仓库改用 `istoreos-25.12`
（内核 6.12，`package/kernel/rockchip-drivers` 为 `6.12_alpha`）重新编译，作为换驱动的验证路径。

## 两个关键改动

1. `scripts/patch-kmods.sh` — 在 `package/diy/dkml/files/kmods.config` 的
   `config global 'kmods'` 下加 `list enable 'rknpu'`。不加这行，开机脚本会给 rknpu 写 blacklist。
2. `configs/r76s.fragment` — 选中 `friendlyarm_nanopi-r76s` 设备与 `kmod-rknpu`，保留 LuCI。

## 触发

Actions → `Build iStoreOS for NanoPi R76S (rknpu enabled)` → Run workflow。
默认编译 `istoreos-25.12`，可在输入框改成分支/tag。首次全量编译约 3–6 小时，job 上限 350 分钟。

## 产物

artifact `istoreos-r76s-rknpu`，其中：

- `*sysupgrade.img.gz` — 用于 SSH 刷写（`sysupgrade`）
- `*factory.img.gz` — 完整镜像，用于写卡/maskrom 恢复
- `profiles.json`、`.config`、`build-tail.log`

## 刷到板子

```sh
scp istoreos-...-sysupgrade.img.gz root@192.168.31.219:/tmp/
ssh root@192.168.31.219 'sysupgrade -T /tmp/istoreos-...-sysupgrade.img.gz'   # 空跑校验，不写盘
ssh root@192.168.31.219 'sysupgrade -v /tmp/istoreos-...-sysupgrade.img.gz'  # 正式刷写，随后自动重启
```

`/mnt/data`（独立分区，Docker 数据与模型都在里面）不受影响；iStoreOS 的 `platform.sh`
默认保留 overlay 分区。跨大版本升级若出现异常，再用 `sysupgrade -n` 清 overlay 重刷。

## 验收

刷完后在板子上执行：

```sh
dmesg | grep -i rknpu          # 不能出现 failed to get ack on domain 'nputop'
ls -l /dev/rknpu
cat /proc/rknpu/version 2>/dev/null || true
```

`/dev/rknpu` 出现即驱动可用，随后把 `librknnrt.so` 放进容器 `docker/vendor/`、
取消 `docker-compose.yml` 里 `devices` 的注释，重建容器即可跑 RKNN 推理。
