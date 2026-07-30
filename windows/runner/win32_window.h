#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>
#include <windowsx.h>

#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    long x;
    long y;
  };
  struct Size {
    long width;
    long height;
  };

  Win32Window();
  virtual ~Win32Window();

  bool Create(const std::wstring& title, Point origin, Size size);
  void Destroy();

  HWND GetHandle() const { return window_handle_; }
  RECT GetClientArea();

  void SetQuitOnClose(bool quit_on_close);
  bool GetQuitOnClose() const;

  virtual LRESULT MessageHandler(HWND window, UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

 protected:
  virtual bool OnCreate();
  virtual void OnDestroy();

  void SetChildContent(HWND content);

 private:
  HWND window_handle_;
  HWND child_content_;
  bool quit_on_close_;

  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  static std::wstring window_class_name_;
};

#endif
