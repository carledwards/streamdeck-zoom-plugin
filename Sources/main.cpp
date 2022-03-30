#include <StreamDeckSDK/ESDLogger.h>
#include <StreamDeckSDK/ESDMain.h>

#include "ZoomStreamDeckPlugin.h"

int main(int argc, const char** argv) {
  // for MacOS, calling NSAppleScript on the "main" thread prevents/reduces the
  // following Apple Script error on the background thread:
  //    "System Events got an error: AppleEvent timed out" 
  std::string status = osGetZoomStatus();
 
  ESDLogger::Get()->SetWin32DebugPrefix("[SDZoom] ");
  return esd_main(argc, argv, new ZoomStreamDeckPlugin());
}
