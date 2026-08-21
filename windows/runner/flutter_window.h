#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>
#include <cstdint>
#include <optional>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void RegisterClipboardChannel();
  void ArmClipboardCapture(std::optional<int64_t> session_id);
  void ResetClipboardCapture();
  void NotifyClipboardChanged();
  void RetryClipboardText();
  static std::optional<std::string> ReadClipboardText();

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      clipboard_channel_;
  bool clipboard_listener_registered_ = false;
  bool clipboard_capture_armed_ = false;
  bool clipboard_change_sent_ = false;
  bool clipboard_notification_sent_ = false;
  std::optional<int64_t> clipboard_capture_session_id_;
  DWORD clipboard_baseline_sequence_ = 0;
  std::optional<std::string> clipboard_pending_text_;
  int clipboard_retry_count_ = 0;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
