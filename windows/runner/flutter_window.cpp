#include "flutter_window.h"

#include <windows.h>

#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/standard_method_codec.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterClipboardChannel();
  clipboard_listener_registered_ =
      AddClipboardFormatListener(GetHandle()) == TRUE;
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  ResetClipboardCapture();
  if (clipboard_listener_registered_) {
    RemoveClipboardFormatListener(GetHandle());
    clipboard_listener_registered_ = false;
  }
  clipboard_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::RegisterClipboardChannel() {
  clipboard_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "dev_orbit/clipboard",
          &flutter::StandardMethodCodec::GetInstance());
  clipboard_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "getChangeCount") {
          result->Success(flutter::EncodableValue(
              static_cast<int64_t>(GetClipboardSequenceNumber())));
          return;
        }
        if (call.method_name() == "armPasteCapture") {
          if (!call.arguments() ||
              !std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
            result->Error("invalid_arguments", "Missing sessionId");
            return;
          }
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          const auto it = args.find(flutter::EncodableValue("sessionId"));
          if (it == args.end() ||
              !std::holds_alternative<int64_t>(it->second)) {
            result->Error("invalid_arguments", "Missing sessionId");
            return;
          }
          ArmClipboardCapture(std::get<int64_t>(it->second));
          result->Success();
          return;
        }
        if (call.method_name() == "discardPendingPasteText") {
          ResetClipboardCapture();
          result->Success();
          return;
        }
        result->NotImplemented();
      });
}

void FlutterWindow::ArmClipboardCapture(std::optional<int64_t> session_id) {
  if (clipboard_capture_armed_ && !clipboard_capture_session_id_ &&
      session_id.has_value()) {
    clipboard_capture_session_id_ = session_id;
    if (clipboard_change_sent_) NotifyClipboardChanged();
    return;
  }
  clipboard_capture_armed_ = true;
  clipboard_change_sent_ = false;
  clipboard_notification_sent_ = false;
  clipboard_capture_session_id_ = session_id;
  clipboard_baseline_sequence_ = GetClipboardSequenceNumber();
  clipboard_pending_text_.reset();
}

void FlutterWindow::ResetClipboardCapture() {
  clipboard_capture_armed_ = false;
  clipboard_change_sent_ = false;
  clipboard_notification_sent_ = false;
  clipboard_capture_session_id_.reset();
  clipboard_baseline_sequence_ = 0;
  clipboard_pending_text_.reset();
}

std::optional<std::string> FlutterWindow::ReadClipboardText() {
  if (!OpenClipboard(nullptr)) return std::nullopt;
  HANDLE handle = GetClipboardData(CF_UNICODETEXT);
  if (!handle) {
    CloseClipboard();
    return std::nullopt;
  }
  const auto* value = static_cast<const wchar_t*>(GlobalLock(handle));
  if (!value) {
    CloseClipboard();
    return std::nullopt;
  }
  const int size = WideCharToMultiByte(
      CP_UTF8, 0, value, -1, nullptr, 0, nullptr, nullptr);
  std::string text;
  if (size > 1) {
    text.resize(static_cast<size_t>(size));
    WideCharToMultiByte(CP_UTF8, 0, value, -1, text.data(), size, nullptr,
                        nullptr);
    text.resize(static_cast<size_t>(size - 1));
  }
  GlobalUnlock(handle);
  CloseClipboard();
  return text;
}

void FlutterWindow::NotifyClipboardChanged() {
  if (!clipboard_channel_ || !clipboard_capture_armed_ ||
      clipboard_notification_sent_ ||
      (!clipboard_change_sent_ &&
       GetClipboardSequenceNumber() == clipboard_baseline_sequence_)) {
    return;
  }
  if (!clipboard_change_sent_) {
    clipboard_change_sent_ = true;
    clipboard_pending_text_ = ReadClipboardText();
  }
  if (!clipboard_capture_session_id_) return;
  clipboard_notification_sent_ = true;
  flutter::EncodableMap arguments;
  arguments[flutter::EncodableValue("sessionId")] =
      flutter::EncodableValue(*clipboard_capture_session_id_);
  if (clipboard_pending_text_.has_value()) {
    arguments[flutter::EncodableValue("text")] =
        flutter::EncodableValue(*clipboard_pending_text_);
  }
  clipboard_channel_->InvokeMethod(
      "clipboardChanged",
      std::make_unique<flutter::EncodableValue>(arguments));
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_ACTIVATE:
      if (LOWORD(wparam) == WA_INACTIVE && !clipboard_capture_armed_) {
        ArmClipboardCapture(std::nullopt);
      }
      break;
    case WM_CLIPBOARDUPDATE:
      NotifyClipboardChanged();
      break;
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
