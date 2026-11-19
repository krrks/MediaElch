if(NOT USE_EXTERN_QUAZIP)
  message(STATUS "Using QuaZip from submodule")
  set(QUAZIP_QT_MAJOR_VERSION
      ${QT_VERSION_MAJOR}
      CACHE STRING "Qt version to use (4, 5 or 6), defaults to 5" FORCE
  )
  option(QUAZIP_BZIP2 "Enables BZIP2 compression" OFF)
  add_subdirectory(quazip)
  if(MSVC AND TARGET QuaZip)
    # QuaZip's Qt compatibility header uses QDateTime APIs that Qt 6.8
    # deprecates. It is vendored third-party code, so silence C4996 for this
    # target only instead of patching the submodule.
    target_compile_options(QuaZip PRIVATE /wd4996)
  endif()
endif()
