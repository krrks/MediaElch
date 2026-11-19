add_subdirectory(mocks)
add_subdirectory(helpers)
add_subdirectory(scrapers)
add_subdirectory(unit)
add_subdirectory(integration)

if(MSVC)
  # Catch2 2.x's single header contains an unguarded `#pragma clang
  # diagnostic`, which MSVC reports as C4068 in every translation unit that
  # includes it. The header is third-party code, so silence the warning for
  # the test binaries instead of patching it.
  foreach(test_target IN ITEMS libmediaelch_testhelpers mediaelch_unit_test mediaelch_test_integration
                               mediaelch_test_scrapers
  )
    if(TARGET ${test_target})
      target_compile_options(${test_target} PRIVATE /wd4068)
    endif()
  endforeach()
endif()
