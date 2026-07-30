#include "win32_window.h"

#include <flutter_windows.h>

#include <dwmapi.h>
#include <stdexcept>

#include "resource.h"

std::wstring Win32Window::window_class_name_;

Win32Window::Win32Window()
    : window_handle_(nullptr),
      child_content_(nullptr),
      quit_on_close_(false) {}

Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::Create(const std::wstring& title, Point origin, Size size) {
  if (!window_class_name_.empty()) {
    window_class_name_ = L"FLUTTER_RUNNER_WIN32_WINDOW";
  }

  HINSTANCE hInstance = GetModuleHandle(nullptr);
  WNDCLASS window_class = {};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = window_class_name_.c_str();
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = hInstance;
  window_class.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
  window_class.hbrBackground = nullptr;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = WndProc;

  RegisterClass(&window_class);

  DWORD style = WS_OVERLAPPEDWINDOW | WS_VISIBLE;
  DWORD exStyle = WS_EX_APPWINDOW;

  RECT rect = {origin.x, origin.y,
               origin.x + size.width, origin.y + size.height};
  AdjustWindowRectEx(&rect, style, FALSE, exStyle);

  window_handle_ = CreateWindowEx(
      exStyle, window_class_name_.c_str(), title.c_str(),
      style, rect.left, rect.top,
      rect.right - rect.left, rect.bottom - rect.top,
      nullptr, nullptr, hInstance, this);

  if (!window_handle_) return false;

  DwmExtendFrameIntoClientArea(window_handle_, nullptr);
  OnCreate();
  return true;
}

void Win32Window::Destroy() {
  OnDestroy();
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  UnregisterClass(window_class_name_.c_str(), GetModuleHandle(nullptr));
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::GetQuitOnClose() const {
  return quit_on_close_;
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
}

bool Win32Window::OnCreate() { return true; }
void Win32Window::OnDestroy() {}

LRESULT Win32Window::MessageHandler(HWND window, UINT const message,
                                     WPARAM const wparam,
                                     LPARAM const lparam) noexcept {
  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message,
                                       WPARAM const wparam,
                                       LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto that = static_cast<Win32Window*>(cs->lpCreateParams);
    that->window_handle_ = window;
  } else if (Win32Window* that = reinterpret_cast<Win32Window*>(GetWindowLongPtr(window, GWLP_USERDATA))) {
    return that->MessageHandler(window, message, wparam, lparam);
  }
  return DefWindowProc(window, message, wparam, lparam);
}
