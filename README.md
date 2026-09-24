# Sonata

一个基于 Flutter 的跨平台音乐播放器（仓库：[tlw00988/sonata](https://github.com/tlw00988/sonata)），既可以连接 Navidrome / OpenSubsonic 音乐服务器播放你的在线曲库，也可以播放本地音频文件。

## 功能

- **在线曲库**：连接 Navidrome 或其他 OpenSubsonic 兼容服务器，浏览歌曲、专辑、艺术家与播放列表
- **本地播放**：扫描设备上的音乐目录，或手动选择文件夹 / 文件进行播放
- **全局搜索**：搜索歌曲、专辑与艺术家
- **播放队列**：查看、增删、清空播放队列
- **收藏**：对歌曲添加 / 移除收藏
- **歌词**：显示当前播放歌曲的歌词
- **封面取色**：根据专辑封面自动生成主题配色，支持系统动态取色（Material You）
- **系统媒体控制**：通知栏、锁屏与桌面媒体键的播放控制及播放状态同步
- **主题模式**：跟随系统 / 浅色 / 深色三种模式可选
- **多语言**：内置英文与简体中文界面，跟随系统语言
- **跨平台**：Android、iOS、Windows、macOS、Linux

## 环境要求

- [Flutter SDK](https://docs.flutter.dev/get-started/install)（stable 渠道，Dart SDK `^3.12.2`）
- 各目标平台的构建工具链：

| 平台 | 额外要求 |
| --- | --- |
| Android | Android SDK、JDK 17 |
| Windows | Visual Studio（含「使用 C++ 的桌面开发」工作负载） |
| Linux | `clang`、`cmake`、`ninja-build`、GTK 3 开发头文件 |
| macOS / iOS | Xcode、CocoaPods |

## 编译

获取源码并拉取依赖：

```bash
git clone https://github.com/tlw00988/sonata.git
cd sonata
flutter pub get
```

运行调试版本（连接已配置好的设备 / 模拟器 / 桌面环境）：

```bash
flutter run
```

构建发布版本：

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release

# iOS（需连接设备或准备归档）
flutter build ipa --release
```

产物位置：

- Android：`build/app/outputs/flutter-apk/`
- Windows：`build/windows/x64/runner/Release/`
- Linux：`build/linux/x64/bundle/`
- macOS：`build/macos/Build/Products/Release/`
- iOS：`build/ios/ipa/`

其他常用命令：

```bash
flutter test      # 运行测试
flutter analyze   # 静态检查
```

> **提示**：Android 的 release 构建目前使用 debug 签名，正式发布前请在
> `android/app/build.gradle.kts` 中配置你自己的签名信息。
> 多语言资源在构建时自动生成，无需额外步骤。

## 配置

所有配置都在应用内完成，无需修改任何文件。

### 1. 连接音乐服务器

进入 **设置 → Navidrome / OpenSubsonic**，填写：

| 配置项 | 说明 |
| --- | --- |
| 服务器地址 | 例如 `https://music.example.com`（结尾的 `/` 可省略） |
| 用户名 | 服务器账号用户名 |
| 密码 | 服务器账号密码 |
| API Key | 可选。填写后优先使用 API Key 认证，此时用户名与密码可不填 |

填写完成后点击 **测试连接**，连接成功即自动保存并生效；点击 **断开连接**
可清除本地保存的服务器配置。配置仅保存在本机。

> 服务器需允许 HTTPS 或处于同一可信网络内，否则可能无法连接。

### 2. 主题外观

**设置 → 外观** 中可选择：

- **系统**：跟随系统深浅色设置（默认）
- **浅色**：始终使用浅色主题
- **深色**：始终使用深色主题

播放时界面配色会随专辑封面变化；系统支持动态取色时会自动采用系统取色。

### 3. 本地音乐

进入 **音乐库 → 本地文件** 标签页：

- **扫描本地目录**：扫描下方「扫描目录」中列出的目录
  （首次启动默认包含：Windows：`用户\音乐`、`下载`、`桌面`；Linux / macOS：`~/Music`、`~/Downloads`；Android / iOS：应用外部存储的 `Music`、`Download`）
- **选择文件夹**：指定任意目录进行扫描，该目录会被记住并加入扫描目录列表
- **添加音频文件**：手动挑选单个或多个文件
- **重新扫描**：刷新当前列表

扫描目录可在 **设置 → 本地音乐** 中添加、移除或一键恢复默认；列表里标红的目录表示当前不存在。
修改后回到音乐库的本地文件标签页重新扫描即可生效。

支持的格式：MP3、FLAC、WAV、OGG、M4A、AAC、OPUS、APE、AIFF、WMA。

播放本地文件时会读取其自带的信息：

- **标签信息**：优先显示文件内嵌的标题、艺术家、专辑、时长、曲号、年份与流派；
  标签缺失时按文件名的「艺术家 - 标题」约定解析。
- **专辑封面**：优先使用文件内嵌的封面，其次使用同目录下的封面图
  （如 `cover.jpg`、`folder.png`，或与音频同名的图片）。
- **歌词**：优先读取同目录下与音频同名的 `.lrc` 文件（自动识别 UTF-8 / UTF-16 /
  GBK 等常见编码），没有外置歌词时读取文件内嵌的歌词。本地歌曲不会向服务器请求歌词。

### 4. 系统权限

- **Android（13 及以上）**：通知栏播放控制需要通知权限，未授予时仅通知栏控制
  不可用，不影响正常播放。
- **本地音乐**：扫描的是应用可直接访问的目录，「添加音频文件」由系统文件选择器
  授权，均无需额外申请存储权限。
- **后台播放（Android）**：已声明前台播放服务，锁屏 / 切到后台时播放不会中断。

### 5. 界面语言

界面语言跟随系统语言，目前支持英文与简体中文。

## 开源协议

本项目基于 **GNU Affero General Public License v3.0（AGPL-3.0）** 开源发布。

你可以自由地使用、修改和分发本项目，但须遵守 AGPL-3.0 的条款，包括：

- 以本协议开源任何基于本项目的衍生作品
- 在提供网络服务时，向其用户提供对应的源代码
- 保留原有的版权声明与协议文本

完整协议文本见仓库根目录的 [LICENSE](LICENSE) 文件，
或访问 [GNU AGPL v3.0](https://www.gnu.org/licenses/agpl-3.0.html)。
