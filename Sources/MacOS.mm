// Martijn Smit <martijn@lostdomain.org / @smitmartijn>
#include "ZoomStreamDeckPlugin.h"
#include <StreamDeckSDK/ESDLogger.h>

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

extern std::string m_zoomMenuMuteAll;
extern std::string m_zoomMenuUnmuteAll;

char *execAndReturn(const char *command)
{
  FILE *fp;
  char *line = NULL;
  // Following initialization is equivalent to char* result = ""; and just
  // initializes result to an empty string, only it works with
  // -Werror=write-strings and is so much less clear.
  char *result = (char *)calloc(1, 1);
  size_t len = 0;

  fflush(NULL);
  fp = popen(command, "r");
  if (fp == NULL)
  {
    printf("Cannot execute command:\n%s\n", command);
    ESDDebug("Cannot execute command:\n%s\n", command);
    return NULL;
  }

  while (getline(&line, &len, fp) != -1)
  {
    // +1 below to allow room for null terminator.
    result = (char *)realloc(result, strlen(result) + strlen(line) + 1);
    // +1 below so we copy the final null terminator.
    strncpy(result + strlen(result), line, strlen(line) + 1);
    free(line);
    line = NULL;
  }

  fflush(fp);
  if (pclose(fp) != 0)
  {
    perror("Cannot close stream.\n");
  }
  return result;
}

std::string osGetZoomStatus()
{
  /*
  Original AS:
  set zoomStatus to "closed"
set muteStatus to "disabled"
set videoStatus to "disabled"
set shareStatus to "disabled"
set recordStatus to "disabled"
tell application "System Events"
	if exists (window 1 of process "zoom.us") then
		set zoomStatus to "open"
		tell application process "zoom.us"
			if exists (menu bar item "Meeting" of menu bar 1) then
				set zoomStatus to "call"
				if exists (menu item "Mute audio" of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set muteStatus to "unmuted"
				else
					set muteStatus to "muted"
				end if
				if exists (menu item "Start Video" of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set videoStatus to "stopped"
				else
					set videoStatus to "started"
				end if
				if exists (menu item "Start Share" of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set shareStatus to "stopped"
				else
					set shareStatus to "started"
				end if
				if exists (menu item "Record to the Cloud" of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set recordStatus to "stopped"
				else if exists (menu item "Record" of menu 1 of menu bar item "Meeting" of menu bar 1) then
					set recordStatus to "stopped"
				else
					set recordStatus to "started"
				end if
			end if
		end tell
	end if
end tell
do shell script "echo zoomMute:" & (muteStatus as text) & ",zoomVideo:" & (videoStatus as text) & ",zoomStatus:" & (zoomStatus as text) & ",zoomShare:" & (shareStatus as text) & ",zoomRecord:" & (recordStatus as text)
  */
  // ESDDebug("APPLESCRIPT_GET_STATUS: %s", APPLESCRIPT_GET_STATUS);
  const std::string appleScript = "set zoomStatus to \"closed\"\n"
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
                                  "			if exists (menu bar item \"" +
                                  m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                      "				set zoomStatus to \"call\"\n"
                                                      "				if exists (menu item \"" +
                                  m_zoomMenuMuteAudio + "\" of menu 1 of menu bar item \"" +
                                  m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                      "					set muteStatus to \"unmuted\"\n"
                                                      "				else\n"
                                                      "					set muteStatus to \"muted\"\n"
                                                      "				end if\n"
                                                      "				if exists (menu item \"" +
                                  m_zoomMenuStartVideo + "\" of menu 1 of menu bar item \"" +
                                  m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                      "					set videoStatus to \"stopped\"\n"
                                                      "				else\n"
                                                      "					set videoStatus to \"started\"\n"
                                                      "				end if\n"
                                                      "				if exists (menu item \"" +
                                  m_zoomMenuStartShare + "\" of menu 1 of menu bar item \"" +
                                  m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                      "					set shareStatus to \"stopped\"\n"
                                                      "				else\n"
                                                      "					set shareStatus to \"started\"\n"
                                                      "				end if\n"
                                                      "				if exists (menu item \"" +
                                  m_zoomMenuStartRecordToCloud + "\" of menu 1 of menu bar item \"" +
                                  m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                      "					set recordStatus to \"stopped\"\n"
                                                      "				else if exists (menu item \"" +
                                  m_zoomMenuStartRecord + "\" of menu 1 of menu bar item \"" +
                                  m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                      "					set recordStatus to \"stopped\"\n"
                                                      "				else\n"
                                                      "					set recordStatus to \"started\"\n"
                                                      "				end if\n"
                                                      "			end if\n"
                                                      "		end tell\n"
                                                      "	end if\n"
                                                      "end tell\n"
                                                      "do shell script \"echo zoomMute:\" & (muteStatus as text) & \",zoomVideo:\" & (videoStatus as text) & \",zoomStatus:\" & (zoomStatus as text) & \",zoomShare:\" & (shareStatus as text) & \",zoomRecord:\" & (recordStatus as text)";

  std::string cmd = "osascript -e '";
  cmd.append(appleScript);
  cmd.append("'");
  char *zoomStatus = execAndReturn(cmd.c_str());

  return std::string(zoomStatus);
}

void osToggleZoomMute()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\"\n"
                             "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "    if exists (menu item \"" +
                             m_zoomMenuUnmuteAudio + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                              "      click (menu item \"" +
                             m_zoomMenuUnmuteAudio + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                              "    else\n"
                                                                                                              "      click (menu item \"" +
                             m_zoomMenuMuteAudio + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                            "    end if\n"
                                                                                                            "  end tell\n"
                                                                                                            "end tell'\n";
  //ESDDebug(script.c_str());
  system(script.c_str());
}

void osToggleZoomShare()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\"\n"
                             "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "    if exists (menu item \"" +
                             m_zoomMenuStartShare + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                             "      click (menu item \"" +
                             m_zoomMenuStartShare + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                             "    else\n"
                                                                                                             "      click (menu item \"" +
                             m_zoomMenuStopShare + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                            "    end if\n"
                                                                                                            "  end tell\n"
                                                                                                            "end tell'\n";
  //ESDDebug(script.c_str());
  system(script.c_str());
}

void osToggleZoomVideo()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\"\n"
                             "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "    if exists (menu item \"" +
                             m_zoomMenuStartVideo + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                             "      click (menu item \"" +
                             m_zoomMenuStartVideo + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                             "    else\n"
                                                                                                             "      click (menu item \"" +
                             m_zoomMenuStopVideo + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                            "    end if\n"
                                                                                                            "  end tell\n"
                                                                                                            "end tell'\n";
  //ESDDebug(script.c_str());
  system(script.c_str());
}

void osLeaveZoomMeeting()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\" to activate\n"
                             "tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "	if exists (menu bar item \"" +
                             m_zoomMenuWindow + "\" of menu bar 1) then\n"
                                                "		click (menu item \"" +
                             m_zoomMenuClose + "\" of menu 1 of menu bar item \"" + m_zoomMenuWindow + "\" of menu bar 1)\n"
                                                                                                       "		delay 0.5\n"
                                                                                                       "		click button 1 of window 1\n"
                                                                                                       "	end if\n"
                                                                                                       "end tell'";
  //ESDDebug(script.c_str());
  system(script.c_str());
}

void osFocusZoomWindow()
{
  const char *script = "osascript -e 'tell application \"zoom.us\"\nactivate\nend tell'";
  //ESDDebug(script);
  system(script);
}

void osToggleZoomRecordCloud()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\"\n"
                             "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "    if exists (menu item \"" +
                             m_zoomMenuStartRecordToCloud + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                                     "      click (menu item \"" +
                             m_zoomMenuStartRecordToCloud + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                                     "    else if exists (menu item \"" +
                             m_zoomMenuStartRecord + "\" of menu 1 of menu bar item \"" +
                             m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                 "      click (menu item \"" +
                             m_zoomMenuStartRecord + "\" of menu 1 of menu bar item \"" +
                             m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                 "    else\n"
                                                 "      click (menu item \"" +
                             m_zoomMenuStopRecordToCloud + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                                    "    end if\n"
                                                                                                                    "  end tell\n"
                                                                                                                    "end tell'\n";
  //ESDDebug(script.c_str());
  system(script.c_str());
}

void osToggleZoomRecordLocal()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\"\n"
                             "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "    if exists (menu item \"" +
                             m_zoomMenuStartRecordLocal + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                                   "      click (menu item \"" +
                             m_zoomMenuStartRecordLocal + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                                   "    else if exists (menu item \"" +
                             m_zoomMenuStartRecord + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                              "      click (menu item \"" +
                             m_zoomMenuStartRecordLocal + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                                   "    else\n"
                                                                                                                   "      click (menu item \"" +
                             m_zoomMenuStopRecordLocal + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                                  "    end if\n"
                                                                                                                  "  end tell\n"
                                                                                                                  "end tell'\n";
  //ESDDebug(script.c_str());
  system(script.c_str());
}

void osMuteAll()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\"\n"
                             "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "    if exists (menu item \"" +
                             m_zoomMenuMuteAll + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                          "      click (menu item \"" +
                             m_zoomMenuMuteAll + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                          "      activate\n"
                                                                                                          "      set frontmost to true\n"
                                                                                                          "      delay 0.5\n"
                                                                                                          "      keystroke return\n"
                                                                                                          "    end if\n"
                                                                                                          "  end tell\n"
                                                                                                          "end tell'\n";
  //ESDDebug(script.c_str());
  system(script.c_str());
}
void osUnmuteAll()
{
  const std::string script = "osascript -e '"
                             "tell application \"zoom.us\"\n"
                             "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                             "    if exists (menu item \"" +
                             m_zoomMenuUnmuteAll + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1) then\n"
                                                                                                            "      click (menu item \"" +
                             m_zoomMenuUnmuteAll + "\" of menu 1 of menu bar item \"" + m_zoomMenuMeeting + "\" of menu bar 1)\n"
                                                                                                            "    end if\n"
                                                                                                            "  end tell\n"
                                                                                                            "end tell'\n";
  //ESDDebug(script.c_str());
  system(script.c_str());
}


void osZoomCustomShortcut(std::string shortcut)
{
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

  const std::string script = "osascript -e '"
                       "tell application \"zoom.us\" to activate\n"
                       "tell application \"zoom.us\"\n"
                       "  tell application \"System Events\" to tell application process \"zoom.us\"\n"
                       "    keystroke \""+as_key+"\" using {"+as_modifiers+"}\n"
                       "  end tell\n"
                       "end tell'";
  //ESDDebug(script.c_str());
  system(script.c_str());
}
