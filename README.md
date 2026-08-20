# Orbit Tools

Orbit Tools 是 DevOrbit 的全新重构版本：一个面向 macOS 和 Windows 的轻量开发工具轮盘。

## 这次为什么重做

旧项目把全局快捷键、窗口切换、工具页面、独立工具进程和剪贴板监听放进同一条控制链，导致一个输入问题会穿透多个平台层。新版本明确切断这条链：

- 单进程、单 Flutter 窗口，状态只有 `hidden / launcher / tool` 三种模式。
- `OrbitCoordinator` 只负责状态迁移，`DesktopHost` 只负责窗口和快捷键。
- 工具是纯领域服务：文本输入 -> 结果输出，不读取或写入系统剪贴板。
- 工具之间没有共享控制器，也不启动独立子窗口。
- 跨应用数据交换只通过用户主动选择的文件导入和导出完成。

## 架构

```text
lib/src/
  domain/       JSON、时间戳、Diff、SQL、DeepL 等无 UI 逻辑
  application/  OrbitCoordinator，唯一的应用状态机
  platform/     window_manager、hotkey_manager、tray_manager、文件选择
  presentation/轮盘、玻璃工作台、工具页
```

系统剪贴板不在依赖、Dart 代码、macOS channel 或 Windows runner 中出现。翻译 API Key 只作为当前请求的输入，不会写入剪贴板或诊断日志。

## 本地开发

需要 Flutter stable（本项目当前按 Dart 3.12 编写）：

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

Windows 构建需要 Visual Studio 的 Desktop C++ 工具链；macOS 构建需要完整 Xcode。应用启动后按 `⌘⇧Space`（Windows 为 `Ctrl⇧Space`）呼出轮盘，数字键 `1-5` 也可直接进入工具。

## GitHub Actions 打包

仓库内置 `.github/workflows/package.yml`：

- Pull Request 和 `main` 推送：运行静态检查和测试。
- GitHub Actions 手动运行：构建 macOS、Windows 压缩包，并在 Actions 的 Artifacts 下载。
- 推送版本标签：构建后自动创建 GitHub Release，并附上两个压缩包。

手动打包：打开 GitHub 仓库的 `Actions`，选择 `Check and Package Orbit Tools`，点击 `Run workflow`。

发布版本：

```bash
git tag v1.0.0
git push origin v1.0.0
```

当前产物是未签名的 `.app` 和 Windows `.zip`。macOS 公证、Windows 安装器和代码签名需要另外配置证书 Secrets，不能只靠 Flutter 构建完成。

## 工具

- JSON Studio：严格校验、修复、格式化、压缩、文件导入/导出
- 翻译：DeepL API Free，当前请求级 API Key
- 文本比对：逐行和字符级变化统计
- 时间戳：秒、毫秒、本地时间互转
- SQL 日志：MyBatis Preparing / Parameters 还原与格式化
