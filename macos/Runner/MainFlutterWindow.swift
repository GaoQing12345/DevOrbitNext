import Cocoa
import FlutterMacOS
import ServiceManagement

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The launcher is drawn as a glass circle. Keep the native window itself
    // transparent so AppKit does not fill the square outside that circle.
    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    contentView?.wantsLayer = true
    contentView?.layer?.backgroundColor = NSColor.clear.cgColor

    FlutterMethodChannel(
      name: "launch_at_startup",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { call, result in
      guard #available(macOS 13.0, *) else {
        result(false)
        return
      }

      switch call.method {
      case "launchAtStartupIsEnabled":
        result(SMAppService.mainApp.status == .enabled)
      case "launchAtStartupSetEnabled":
        guard
          let arguments = call.arguments as? [String: Any],
          let enabled = arguments["setEnabledValue"] as? Bool
        else {
          result(FlutterError(
            code: "invalid_arguments",
            message: "setEnabledValue must be a boolean",
            details: nil
          ))
          return
        }

        do {
          if enabled {
            try SMAppService.mainApp.register()
          } else {
            try SMAppService.mainApp.unregister()
          }
          result(nil)
        } catch {
          result(FlutterError(
            code: "launch_at_startup",
            message: error.localizedDescription,
            details: nil
          ))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
