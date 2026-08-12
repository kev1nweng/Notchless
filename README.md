# Notchless

A small native macOS menu bar app that places a solid black panel behind the system menu bar, visually blending the display notch into the bar without modifying the wallpaper.

## Features

- Works with static and dynamic wallpapers
- Native menu bar controls
- Optional automatic hiding during lock and unlock transitions
- Multi-display and Space support
- English, Simplified Chinese, and Traditional Chinese localization
- No Accessibility or Screen Recording permission required

## Requirements

- macOS 14 or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to regenerate the project

For the overlay to remain visible, turn off **Show menu bar background** in **System Settings › Menu Bar**. Reduce Transparency can also prevent the system menu bar material from revealing the overlay.

## Build

```sh
xcodegen generate
xcodebuild -project Notchless.xcodeproj \
  -scheme Notchless \
  -configuration Debug \
  -derivedDataPath DerivedData \
  build
```

Unsigned development builds are also available from [GitHub Releases](https://github.com/kev1nweng/Notchless/releases).

The locally built app is located at:

```text
DerivedData/Build/Products/Debug/Notchless.app
```

## How it works

Notchless creates one non-interactive `NSPanel` per display and places it immediately below the system status-window level:

```swift
CGWindowLevelForKey(.statusWindow) - 1
```

The system menu bar remains responsible for rendering its menus and status items. Notchless only supplies a black compositing surface behind it, so no process injection, private framework, Accessibility permission, or Screen Recording permission is required.

## License

[MIT](LICENSE)
