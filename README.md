# Notchless

**简体中文 / [English](README.en.md)**

一款极简的 macOS 刘海隐藏工具，不修改壁纸。

## 功能

- 以纯黑菜单栏隐藏屏幕刘海
- 支持静态与动态壁纸
- 原生、极简的菜单栏控制
- 支持多显示器与桌面空间
- 可在锁屏与解锁时自动隐藏、恢复
- 无需辅助功能或屏幕录制权限

## 安装

从 [Releases](https://github.com/kev1nweng/Notchless/releases) 下载最新的 `Notchless.zip`，解压后将应用移动到“应用程序”文件夹。

当前 Release 未签名。首次运行时，可能需要在“系统设置 › 隐私与安全性”中手动允许打开。

> 若效果不可见，请在“系统设置 › 菜单栏”中关闭“显示菜单栏背景”。开启“降低透明度”也可能遮挡效果。

## 从源码构建

需要 macOS 14 或更高版本、Xcode 16 或更高版本，以及 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

```sh
xcodegen generate
xcodebuild -project Notchless.xcodeproj \
  -scheme Notchless \
  -configuration Debug \
  -derivedDataPath DerivedData \
  build
```

构建产物位于：

```text
DerivedData/Build/Products/Debug/Notchless.app
```

## 原理

Notchless 为每块显示器创建一个不可交互的 `NSPanel`，并将其置于系统菜单栏之后：

```swift
CGWindowLevelForKey(.statusWindow) - 1
```

系统仍负责绘制菜单与状态图标；Notchless 仅在其背后提供纯黑合成表面，不注入系统进程，也不依赖私有框架。

## 许可证

[MIT](LICENSE)
