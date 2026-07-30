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
    Point() : x(0), y(0) {}
    Point(long x, long y) : x(x), y(y) {}
    long x;
    long y;
  };
  struct Size {
    Size() : width(0), height(0) {}
    Size(long width, long height) : width(width), height(height) {}
    long width;
    long height;
  };

  Win32Window();
  virtual ~Win32Window();

  bool Create(const std::wstring& title, Point origin, Size size);
  void Destroy();

  void Show();
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
