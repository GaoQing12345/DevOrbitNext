import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Orbit Tools is a tray app. Hiding the only window must leave the process
    // alive so the tray icon and global shortcut continue to work.
    return false
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Keep the app out of the Dock while it is resident in the tray.
    NSApp.setActivationPolicy(.accessory)
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
