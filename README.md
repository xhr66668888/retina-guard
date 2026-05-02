# Retina Guard

A minimal Windows 11 ARM64 desktop app that reminds you to look into the distance every 20 minutes to reduce retinal stress.

一个极简的 Windows 11 ARM64 桌面应用：每 20 分钟弹窗提醒你眺望远方，降低视网膜牵拉风险。

## How it works / 工作原理

| Click **Start** → counts down from 20:00 → popup reminder → click OK → next cycle begins. |
| --- |

| 点击 **Start** → 20 分钟倒计时 → 弹窗提醒 → 点击 OK → 自动下一轮。 |
| --- |

## Why / 背景

High myopia (long axial length) stretches the retina thin, significantly increasing the risk of retinal tears and detachment. The 20-20-20 rule (every 20 min, look 20 ft away for 20 sec) helps relax the ciliary muscle and reduce vitreoretinal traction.

高度近视（长眼轴）使视网膜变薄，显著增加裂孔和脱离风险。20-20-20 法则有助于放松睫状肌、减少玻璃体对视网膜的牵拉。

## Download / 下载

Download `retina-guard.exe` from the [Releases](https://github.com/xhr66668888/retina-guard/releases) page. No installation required — double-click to run.

从 [Releases](https://github.com/xhr66668888/retina-guard/releases) 页面下载 `retina-guard.exe`，无需安装，双击即可运行。

## Build from source / 从源码编译

```bash
GOOS=windows GOARCH=arm64 go build -ldflags="-s -w -H windowsgui" -o retina-guard.exe .
```

Requires Go 1.22+. Zero external dependencies.
需要 Go 1.22+，零外部依赖。
