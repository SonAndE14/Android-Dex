cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_SOURCE_DIR}/ephemeral")

add_library(flutter_wrapper_plugin STATIC
  "${FLUTTER_ROOT}/packages/flutter_tools/templates/app/windows/flutter/ephemeral/cpp/flutter_plugin.cpp"
)
target_include_directories(flutter_wrapper_plugin
  PUBLIC "${FLUTTER_ROOT}/packages/flutter_tools/templates/app/windows/flutter/ephemeral"
  PRIVATE "${FLUTTER_ROOT}/packages/flutter_tools/templates/app/windows/flutter/ephemeral/cpp"
)
target_link_libraries(flutter_wrapper_plugin PUBLIC flutter)
add_dependencies(flutter_wrapper_plugin flutter)

add_library(flutter_wrapper_app STATIC
  "${FLUTTER_ROOT}/packages/flutter_tools/templates/app/windows/flutter/ephemeral/cpp/flutter_engine.cpp"
)
target_include_directories(flutter_wrapper_app
  PUBLIC "${FLUTTER_ROOT}/packages/flutter_tools/templates/app/windows/flutter/ephemeral"
  PRIVATE "${FLUTTER_ROOT}/packages/flutter_tools/templates/app/windows/flutter/ephemeral/cpp"
)
target_link_libraries(flutter_wrapper_app PUBLIC flutter)
add_dependencies(flutter_wrapper_app flutter)

set(dependencies
  "${EPHEMERAL_DIR}/flutter_windows.dll"
  "${EPHEMERAL_DIR}/flutter_export.h"
  "${EPHEMERAL_DIR}/flutter_messenger.h"
  "${EPHEMERAL_DIR}/flutter_plugin_registrar.h"
  "${EPHEMERAL_DIR}/flutter_texture_registrar.h"
  "${EPHEMERAL_DIR}/icudtl.dat"
)

foreach(dep ${dependencies})
  add_custom_command(OUTPUT ${dep}
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${FLUTTER_ROOT}/bin/cache/artifacts/engine/windows-x64/${dep}"
      "${dep}"
    DEPENDS flutter
  )
endforeach()

add_custom_target(flutter_assemble DEPENDS ${dependencies})
