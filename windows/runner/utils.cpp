#include "utils.h"

#include <flutter_windows.h>

#include <Shlwapi.h>
#include <shellapi.h>
#include <algorithm>

void CreateAndAttachConsole() {
  ::AllocConsole();
}

std::vector<std::string> GetCommandLineArguments() {
  int argc;
  LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  std::vector<std::string> args;
  if (argv) {
    for (int i = 1; i < argc; i++) {
      int size = WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, nullptr, 0, nullptr, nullptr);
      if (size > 0) {
        std::string arg(size - 1, 0);
        WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, arg.data(), size, nullptr, nullptr);
        args.push_back(arg);
      }
    }
    LocalFree(argv);
  }
  return args;
}
