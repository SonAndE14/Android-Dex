cmake_minimum_required(VERSION 3.14)
project(android_dex LANGUAGES CXX)

set(BINARY_NAME "android_dex_win")
set(APPLICATION_ID "com.androiddex.app")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

configure_file(
  "${CMAKE_SOURCE_DIR}/flutter/CMakeLists.txt"
  "${CMAKE_BINARY_DIR}/flutter/CMakeLists.txt"
  COPYONLY
)

configure_file(
  "${CMAKE_SOURCE_DIR}/runner/CMakeLists.txt"
  "${CMAKE_BINARY_DIR}/runner/CMakeLists.txt"
  COPYONLY
)

add_subdirectory("${CMAKE_BINARY_DIR}/flutter" flutter)
add_subdirectory("${CMAKE_BINARY_DIR}/runner" runner)

if(PLATFORM_NAME)
  target_compile_definitions(runner PRIVATE PLATFORM_NAME="${PLATFORM_NAME}")
endif()

install(TARGETS runner RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}")
install(DIRECTORY "${FLUTTER_ROOT}/bin/cache/artifacts/engine/windows-x64"
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
  FILES_MATCHING PATTERN "*.dll"
)
install(FILES "${CMAKE_SOURCE_DIR}/assets/adb/adb.exe" DESTINATION "${CMAKE_INSTALL_PREFIX}")
install(FILES "${CMAKE_SOURCE_DIR}/assets/scrcpy/scrcpy.exe" DESTINATION "${CMAKE_INSTALL_PREFIX}")
