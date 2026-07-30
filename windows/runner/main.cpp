#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    ::AllocConsole();
  }

  Utils::InitializeCOM();

  FlutterDesktopEngineProperties engine_properties;
  engine_properties.assets_path = L"data\\flutter_assets";
  engine_properties.icu_data_path = L"icudtl.dat";
  engine_properties.command_line = command_line;
  engine_properties.aot_library_path = nullptr;

  std::vector<std::string> command_line_arguments =
      Utils::ConvertFlutterArgsToCommandLineArguments();

  FlutterDesktopEngineState *state =
      FlutterDesktopEngineCreate(&engine_properties);
  if (!state) {
    return EXIT_FAILURE;
  }

  FlutterViewController view_controller(state);
  auto result = view_controller.RunWindow();
  if (result != EXIT_SUCCESS) {
    return result;
  }

  FlutterDesktopEngineRun(state, nullptr);
  FlutterDesktopEngineShutDown(state);

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
