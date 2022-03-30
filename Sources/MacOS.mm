// Martijn Smit <martijn@lostdomain.org / @smitmartijn>

#define NDEBUG
// uncomment if you want debugging output (errors are always logged)
// #undef NDEBUG

#include "ZoomStreamDeckPlugin.h"
#include <StreamDeckSDK/ESDLogger.h>
#include <Foundation/Foundation.h>

extern std::string m_zoomMenuMeeting;
extern std::string m_zoomMenuMuteAudio;
extern std::string m_zoomMenuUnmuteAudio;

extern std::string m_zoomMenuStartVideo;
extern std::string m_zoomMenuStopVideo;

extern std::string m_zoomMenuStartShare;
extern std::string m_zoomMenuStopShare;

extern std::string m_zoomMenuStartRecordToCloud;
extern std::string m_zoomMenuStopRecordToCloud;

extern std::string m_zoomMenuStartRecord;

extern std::string m_zoomMenuStartRecordLocal;
extern std::string m_zoomMenuStopRecordLocal;

extern std::string m_zoomMenuWindow;
extern std::string m_zoomMenuClose;
extern std::string m_zoomMenuZoomMeeting;

extern std::string m_zoomMenuMuteAll;
extern std::string m_zoomMenuUnmuteAll;

int zoomStatusSkipCount = 0;

std::string osGetZoomStatus() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
        "set zoomStatus to \"closed\"\n"
        "set muteStatus to \"disabled\"\n"
        "set videoStatus to \"disabled\"\n"
        "set shareStatus to \"disabled\"\n"
        "set recordStatus to \"disabled\"\n"
        "set speakerViewStatus to \"disabled\"\n"
        "set minimalView to \"disabled\"\n"
        "tell application \"System Events\"\n"
        "	if (get name of every application process) contains \"zoom.us\" then\n"
        "		set zoomStatus to \"open\"\n"
        "		tell application process \"zoom.us\"\n"
        "			if exists (menu bar item \"%@\" of menu bar 1) then\n"
        "				set zoomStatus to \"call\"\n"
        "				if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "					set muteStatus to \"unmuted\"\n"
        "				else\n"
        "					set muteStatus to \"muted\"\n"
        "				end if\n"
        "				if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "					set videoStatus to \"stopped\"\n"
        "				else\n"
        "					set videoStatus to \"started\"\n"
        "				end if\n"
        "				if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "					set shareStatus to \"stopped\"\n"
        "				else\n"
        "					set shareStatus to \"started\"\n"
        "				end if\n"
        "				if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "					set recordStatus to \"stopped\"\n"
        "				else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "					set recordStatus to \"stopped\"\n"
        "				else\n"
        "					set recordStatus to \"started\"\n"
        "				end if\n"
        "			end if\n"
        "		end tell\n"
        "	end if\n"
        " return \"zoomMute:\" & (muteStatus as text) & \",zoomVideo:\" & (videoStatus as text) & \",zoomStatus:\" & (zoomStatus as text) & \",zoomShare:\" & (shareStatus as text) & \",zoomRecord:\" & (recordStatus as text)\n"
        "end tell\n",
      [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuMuteAudio.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuStartVideo.c_str()],
      [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuStartShare.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuStartRecordToCloud.c_str()],
      [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuStartRecord.c_str()], 
      [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()]
    ];

    // ESDDebug("osGetZoomStatus script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    ESDDebug("osGetZoomStatus result: %s", [[theResult description] cStringUsingEncoding: NSUTF8StringEncoding]);
    if (errorInfo) {
      ESDLog("osGetZoomStatus errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }

    // Zoom menus are not updated quickly to reflect the most recent toggle (e.g. mute, video, share)
    // we will skip a specified number of the status calls so the buttons on the Stream Deck don't show 
    // the incorrect states (this takes about 3 seconds)
    return std::string(zoomStatusSkipCount-- > 0 || errorInfo ? "" : [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
  }
}

void osToggleZoomMute() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
          "tell application \"System Events\"\n"
          "  set didRun to false\n"
          "  if (get name of every application process) contains \"zoom.us\" then\n"
          "    tell application process \"zoom.us\"\n"
          "      if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
          "        click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
          "        set didRun to true\n"
          "      else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
          "        click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
          "        set didRun to true\n"
          "      end if\n"
          "    end tell\n"
          "  end if\n"
          "  return didRun\n"
          "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuUnmuteAudio.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuUnmuteAudio.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMuteAudio.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuMuteAudio.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()] 
      ];
    ESDDebug("osToggleZoomMute script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osToggleZoomMute errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osToggleZoomMute didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
      if ([@"true" isEqualTo:theResult]) {
        zoomStatusSkipCount = 2;
      }
    }
  }
}

void osToggleZoomShare() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
          "tell application \"System Events\"\n"
          "  set didRun to false\n"
          "  if (get name of every application process) contains \"zoom.us\" then\n"
          "    tell application process \"zoom.us\"\n"
          "      if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
          "        click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
          "        set didRun to true\n"
          "      else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
          "        click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
          "        set didRun to true\n"
          "      end if\n"
          "    end tell\n"
          "  end if\n"
          "  return didRun\n"
          "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuStartShare.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartShare.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStopShare.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuStopShare.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()] 
      ];
    ESDDebug("osToggleZoomShare script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osToggleZoomShare errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osToggleZoomShare didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
      if ([@"true" isEqualTo:theResult]) {
        zoomStatusSkipCount = 2;
      }
    }
  }
}

void osToggleZoomVideo() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
          "tell application \"System Events\"\n"
          "  set didRun to false\n"
          "  if (get name of every application process) contains \"zoom.us\" then\n"
          "    tell application process \"zoom.us\"\n"
          "      if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
          "        click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
          "        set didRun to true\n"
          "      else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
          "        click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
          "        set didRun to true\n"
          "      end if\n"
          "    end tell\n"
          "  end if\n"
          "  return didRun\n"
          "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuStartVideo.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartVideo.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStopVideo.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuStopVideo.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()] 
      ];
    ESDDebug("osToggleZoomVideo script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osToggleZoomVideo errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osToggleZoomVideo didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
      if ([@"true" isEqualTo:theResult]) {
        zoomStatusSkipCount = 2;
      }
    }
  }
}

void osLeaveZoomMeeting() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
        "tell application \"System Events\"\n"
        "  set didRun to false\n"
        "  if (get name of every application process) contains \"zoom.us\" then\n"
        "    tell application \"System Events\" to tell application process \"zoom.us\"\n"
        "      if exists (menu bar item \"Meeting\" of menu bar 1) then\n"
        "        if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "          tell application \"zoom.us\" to activate\n"
        "          click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "          click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "          delay 0.5\n"
        "          click button 1 of window 1\n"
        "          set didRun to true\n"
        "        end if\n"
        "      end if\n"
        "    end tell\n"
        "  end if\n"
        "  return didRun\n"
        "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuZoomMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuWindow.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuZoomMeeting.c_str()],
        [NSString stringWithUTF8String:m_zoomMenuWindow.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuClose.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuWindow.c_str()] 
      ];
    ESDDebug("osLeaveZoomMeeting script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osLeaveZoomMeeting errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osLeaveZoomMeeting didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  }  
}

void osFocusZoomWindow() {
  @autoreleasepool
  {
    NSString *source = @""
          "tell application \"zoom.us\"\n"
          "  activate\n"
          "end tell\n";
    ESDDebug("osFocusZoomWindow script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osFocusZoomWindow errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  }
}

void osToggleZoomRecordCloud() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
        "tell application \"System Events\"\n"
        "	set didRun to false\n"
        "	if (get name of every application process) contains \"zoom.us\" then\n"
        "		tell application \"System Events\" to tell application process \"zoom.us\"\n"
        "			if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			end if\n"
        "		end tell\n"
        "	end if\n"
        "	return didRun\n"
        "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuStartRecordToCloud.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartRecordToCloud.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartRecord.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartRecord.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStopRecordToCloud.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStopRecordToCloud.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()]
      ];
    ESDDebug("osToggleZoomRecordCloud script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osToggleZoomRecordCloud errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osToggleZoomRecordCloud didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  }  
}

void osToggleZoomRecordLocal() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
        "tell application \"System Events\"\n"
        "	set didRun to false\n"
        "	if (get name of every application process) contains \"zoom.us\" then\n"
        "		tell application \"System Events\" to tell application process \"zoom.us\"\n"
        "			if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			else if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			end if\n"
        "		end tell\n"
        "	end if\n"
        "	return didRun\n"
        "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuStartRecordLocal.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartRecordLocal.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartRecord.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStartRecord.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStopRecordLocal.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuStopRecordLocal.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()]
      ];
    ESDDebug("osToggleZoomRecordLocal script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osToggleZoomRecordLocal errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osToggleZoomRecordLocal didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  }  
}

void osMuteAll() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
        "tell application \"System Events\"\n"
        "	set didRun to false\n"
        "	if (get name of every application process) contains \"zoom.us\" then\n"
        "		tell application \"System Events\" to tell application process \"zoom.us\"\n"
        "			if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			end if\n"
        "		end tell\n"
        "	end if\n"
        "	return didRun\n"
        "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuMuteAll.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMuteAll.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()] 
      ];
    ESDDebug("osMuteAll script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osMuteAll errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osMuteAll didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  }  
}

void osUnmuteAll() {
  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
        "tell application \"System Events\"\n"
        "	set didRun to false\n"
        "	if (get name of every application process) contains \"zoom.us\" then\n"
        "		tell application \"System Events\" to tell application process \"zoom.us\"\n"
        "			if exists (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1) then\n"
        "				click (menu item \"%@\" of menu 1 of menu bar item \"%@\" of menu bar 1)\n"
        "				set didRun to true\n"
        "			end if\n"
        "		end tell\n"
        "	end if\n"
        "	return didRun\n"
        "end tell\n",
        [NSString stringWithUTF8String:m_zoomMenuUnmuteAll.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuUnmuteAll.c_str()], 
        [NSString stringWithUTF8String:m_zoomMenuMeeting.c_str()] 
      ];
    ESDDebug("osUnmuteAll script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osUnmuteAll errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osUnmuteAll didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  }  
}

void osZoomCustomShortcut(std::string shortcut) {
  // build the apple script based on the incoming shortcut. Modifiers should always be first, so first check for mod keys, then move on to the key
  std::string s = shortcut;
  std::string delimiter = "+";

  /*
    We want to build something like this:

    tell application "zoom.us" to activate
    tell application "zoom.us"
      tell application "System Events" to tell application process "zoom.us"
        keystroke "v" using {shift down, command down}
      end tell
    end tell
  */

  std::string as_modifiers = "";
  std::string as_key       = "";
  // "explode" the shortcut using '+' as the delimiter, by finding the first instance of the delimiter, substr()'ing that part and then deleting the first part and move on
  size_t pos = 0;
  std::string token;
  while ((pos = s.find(delimiter)) != std::string::npos)
  {
    token = s.substr(0, pos);
    //ESDDebug("Token: %s", token.c_str());
    //ESDDebug("s: %s", s.c_str());
    s.erase(0, pos + delimiter.length());
    //ESDDebug("s: %s", s.c_str());


    if(token == "shift") {
      as_modifiers += "shift down, ";
    }
    else if(token == "command") {
      as_modifiers += "command down, ";
    }
    else if(token == "control") {
      as_modifiers += "control down, ";
    }
    else if(token == "option") {
      as_modifiers += "option down, ";
    }
    else {
      // regular key!
      // we're assuming that nothing comes after the key, which it shouldn't, so we might as well break
      break;
    }
  }

  // the leftover will be the key itself
  as_key = s;
  // convert string to upper case
  std::for_each(as_key.begin(), as_key.end(), [](char & c){
    c = ::tolower(c);
  });

  // remove the last ", " from the modifiers string
  as_modifiers = as_modifiers.substr(0, as_modifiers.size()-2);

  @autoreleasepool
  {
    NSString *source = [NSString stringWithFormat:@""
        "tell application \"System Events\"\n"
        "	set didRun to false\n"
        "	if (get name of every application process) does not contain \"zoom.us\" then\n"
        "		tell application \"zoom.us\" to activate\n"
        "		delay 3\n"
        "	else\n"
        "		tell application \"zoom.us\" to activate\n"
        "	end if\n"
        "	tell application \"System Events\" to tell application process \"zoom.us\"\n"
        "		keystroke \"%@\" using {%@}\n"
        "		set didRun to true\n"
        "	end tell\n"
        "	return didRun\n"
        "end tell\n",
        [NSString stringWithUTF8String:as_key.c_str()], 
        [NSString stringWithUTF8String:as_modifiers.c_str()]
      ];
    ESDDebug("osZoomCustomShortcut script: %s", [source cStringUsingEncoding: NSUTF8StringEncoding]);
    NSDictionary *errorInfo = nil;
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:source];
    NSAppleEventDescriptor *theDescriptor = [appleScript executeAndReturnError:&errorInfo];
    NSString *theResult = [theDescriptor stringValue];
    [appleScript release];
    if (errorInfo) {
      ESDLog("osZoomCustomShortcut errorInfo: %s", [[errorInfo description] cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    else {
      ESDDebug("osZoomCustomShortcut didRun: %s", [theResult cStringUsingEncoding: NSUTF8StringEncoding]);
    }
  }  
}