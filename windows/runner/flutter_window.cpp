#include "flutter_window.h"
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <optional>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : flutter_view_controller_(std::make_unique<flutter::FlutterViewController>(
          FlutterDesktopEngineCreate(
              const_cast<FlutterDesktopEngineProperties*>(
                  project.GetEngineProperties())))) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_view_controller_->CreateNativeWindow(
      "Android DEX", frame.right - frame.left, frame.bottom - frame.top);

  SetChildContent(flutter_view_controller_->GetNativeWindow());

  flutter_view_controller_->SendInitialChannelData();
  return true;
}

void FlutterWindow::OnDestroy() {
  flutter_view_controller_.reset();
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND window, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  return Win32Window::MessageHandler(window, message, wparam, lparam);
}
