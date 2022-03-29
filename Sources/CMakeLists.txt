set(CMAKE_CXX_STANDARD 20)

set(
  SOURCES
  ZoomStreamDeckPlugin.cpp
  main.cpp
)

if(WIN32)
  set(SOURCES
    ${SOURCES}
    Windows.cpp
  )
endif()

if(APPLE)
  set(SOURCES
    ${SOURCES}
    MacOS.mm
  )
  find_library(FOUNDATION_LIBRARY Foundation)
  SET(EXTRA_LIBS ${FOUNDATION_LIBRARY})
endif()

add_executable(
  sdzoomplugin
  ${SOURCES}
)
target_link_libraries(sdzoomplugin json StreamDeckSDK)
install(TARGETS sdzoomplugin DESTINATION ${CMAKE_INSTALL_PREFIX})
