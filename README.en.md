# Notchless

**[简体中文](README.md) / English**

A minimal macOS utility that hides the display notch without modifying your wallpaper.

## Features

- Hides the notch with a solid black menu bar
- Works with static and dynamic wallpapers
- Minimal, native menu bar controls
- Supports multiple displays and Spaces
- Optionally hides and restores itself during lock transitions
- Requires no Accessibility or Screen Recording permission

## Install

Download the latest `Notchless.zip` from [Releases](https://github.com/kev1nweng/Notchless/releases), extract it, and move the app to Applications.

Current release builds are unsigned. On first launch, you may need to allow the app in **System Settings › Privacy & Security**.

> If the effect is not visible, turn off **Show menu bar background** in **System Settings › Menu Bar**. Reduce Transparency may also obscure the effect.

## Build from source

Requires macOS 14 or later, Xcode 16 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
xcodebuild -project Notchless.xcodeproj \
  -scheme Notchless \
  -configuration Debug \
  -derivedDataPath DerivedData \
  build
```

The built app is located at:

```text
DerivedData/Build/Products/Debug/Notchless.app
```

## How it works

Notchless creates one non-interactive `NSPanel` per display and places it immediately behind the system menu bar:

```swift
CGWindowLevelForKey(.statusWindow) - 1
```

macOS remains responsible for rendering menus and status items. Notchless only supplies a black compositing surface behind them—without process injection or private frameworks.

## License

[MIT](LICENSE)
