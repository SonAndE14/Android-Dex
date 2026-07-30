cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_SOURCE_DIR}/ephemeral")

add_executable(runner
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "Runner.rc"
)

target_include_directories(runner PRIVATE
  "${CMAKE_SOURCE_DIR}"
  "${EPHEMERAL_DIR}"
)

target_link_libraries(runner
  PRIVATE flutter_wrapper_app
  PRIVATE flutter_wrapper_plugin
  PRIVATE dwmapi
  PRIVATE comctl32
  PRIVATE gdi32
  PRIVATE imm32
  PRIVATE ole32
  PRIVATE shell32
  PRIVATE shlwapi
  PRIVATE user32
  PRIVATE winmm
  PRIVATE ws2_32
)

target_compile_definitions(runner PRIVATE
  NDEBUG
  UNICODE
  _UNICODE
)

set(flutter_assets "${CMAKE_SOURCE_DIR}/ephemeral/flutter_assets")
add_custom_command(TARGET runner POST_BUILD
  COMMAND "${CMAKE_COMMAND}" -E copy_if_different
    "${EPHEMERAL_DIR}/flutter_windows.dll"
    "${CMAKE_BINARY_DIR}/runner/Release/"
  COMMAND "${CMAKE_COMMAND}" -E copy_directory
    "${flutter_assets}"
    "${CMAKE_BINARY_DIR}/runner/Release/data/flutter_assets"
)

install(TARGETS runner RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}")
