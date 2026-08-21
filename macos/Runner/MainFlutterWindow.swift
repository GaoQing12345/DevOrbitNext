import Cocoa
import FlutterMacOS
import ServiceManagement

class MainFlutterWindow: NSWindow {
  private var clipboardChannel: FlutterMethodChannel?
  private var clipboardTimer: Timer?
  private var clipboardCaptureArmed = false
  private var clipboardCaptureSessionId: Int64?
  private var clipboardBaselineChangeCount = 0
  private var clipboardChangeSent = false
  private var clipboardPendingText: String?
  private var clipboardCaptureStartedAt = Date()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The launcher is drawn as a glass circle. Keep the native window itself
    // transparent so AppKit does not fill the square outside that circle.
    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.isOpaque = false
    flutterViewController.view.layer?.backgroundColor = NSColor.clear.cgColor
    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    contentView?.wantsLayer = true
    contentView?.layer?.backgroundColor = NSColor.clear.cgColor

    FlutterMethodChannel(
      name: "dev_orbit/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { call, result in
      switch call.method {
      case "activate":
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        result(nil)
      case "setLauncherMask":
        let arguments = call.arguments as? [String: Any]
        let enabled = arguments?["enabled"] as? Bool ?? false
        self.setLauncherMask(enabled)
        result(nil)
      case "cursorScreenPoint":
        let primaryHeight = NSScreen.screens.first?.frame.maxY ?? 0
        let mouse = NSEvent.mouseLocation
        result(["dx": mouse.x, "dy": primaryHeight - mouse.y])
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let clipboardChannel = FlutterMethodChannel(
      name: "dev_orbit/clipboard",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    self.clipboardChannel = clipboardChannel
    clipboardChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "armPasteCapture":
        guard
          let arguments = call.arguments as? [String: Any],
          let value = arguments["sessionId"] as? NSNumber
        else {
          result(FlutterError(
            code: "invalid_arguments",
            message: "sessionId must be an integer",
            details: nil
          ))
          return
        }
        self.armClipboardCapture(sessionId: value.int64Value)
        result(nil)
      case "discardPendingPasteText":
        self.resetClipboardCapture()
        result(nil)
      case "getChangeCount":
        result(NSPasteboard.general.changeCount)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

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
    setLauncherMask(true)
  }

  private func setLauncherMask(_ enabled: Bool) {
    guard let content = contentView else { return }
    content.wantsLayer = true
    if enabled {
      content.layoutSubtreeIfNeeded()
      let bounds = content.bounds
      let mask = CAShapeLayer()
      mask.frame = bounds
      mask.path = CGPath(
        ellipseIn: bounds.insetBy(dx: 1, dy: 1),
        transform: nil
      )
      content.layer?.mask = mask
      content.layer?.backgroundColor = NSColor.clear.cgColor
    } else {
      content.layer?.mask = nil
    }
  }

  private func armClipboardCapture(sessionId: Int64) {
    if clipboardCaptureArmed, clipboardCaptureSessionId == nil {
      clipboardCaptureSessionId = sessionId
      if clipboardChangeSent {
        notifyClipboardChange()
      }
      return
    }
    resetClipboardCapture()
    clipboardCaptureArmed = true
    clipboardCaptureSessionId = sessionId
    clipboardBaselineChangeCount = NSPasteboard.general.changeCount
    clipboardCaptureStartedAt = Date()
    clipboardTimer = Timer.scheduledTimer(
      withTimeInterval: 0.025,
      repeats: true
    ) { [weak self] _ in
      self?.pollClipboardCapture()
    }
  }

  private func pollClipboardCapture() {
    guard clipboardCaptureArmed, !clipboardChangeSent else { return }
    if clipboardCaptureSessionId == nil,
       Date().timeIntervalSince(clipboardCaptureStartedAt) > 15 {
      resetClipboardCapture()
      return
    }
    let pasteboard = NSPasteboard.general
    guard pasteboard.changeCount != clipboardBaselineChangeCount else { return }
    clipboardChangeSent = true
    clipboardPendingText = pasteboard.string(forType: .string)
    notifyClipboardChange()
  }

  private func notifyClipboardChange() {
    guard let sessionId = clipboardCaptureSessionId else { return }
    var arguments: [String: Any] = ["sessionId": sessionId]
    if let text = clipboardPendingText {
      arguments["text"] = text
    }
    clipboardChannel?.invokeMethod("clipboardChanged", arguments: arguments)
  }

  private func resetClipboardCapture() {
    clipboardTimer?.invalidate()
    clipboardTimer = nil
    clipboardCaptureArmed = false
    clipboardCaptureSessionId = nil
    clipboardBaselineChangeCount = 0
    clipboardChangeSent = false
    clipboardPendingText = nil
    clipboardCaptureStartedAt = Date()
  }

  override func resignKey() {
    if !clipboardCaptureArmed {
      resetClipboardCapture()
      clipboardCaptureArmed = true
      clipboardBaselineChangeCount = NSPasteboard.general.changeCount
      clipboardCaptureStartedAt = Date()
      clipboardTimer = Timer.scheduledTimer(
        withTimeInterval: 0.025,
        repeats: true
      ) { [weak self] _ in
        self?.pollClipboardCapture()
      }
    }
    super.resignKey()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
