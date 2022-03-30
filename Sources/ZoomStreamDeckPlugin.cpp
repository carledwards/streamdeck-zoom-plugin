// Martijn Smit <martijn@lostdomain.org / @smitmartijn>
#include "ZoomStreamDeckPlugin.h"

#include <StreamDeckSDK/EPLJSONUtils.h>
#include <StreamDeckSDK/ESDConnectionManager.h>
#include <StreamDeckSDK/ESDLogger.h>

#include <atomic>
#include <iostream>
#include <mutex>
#include <vector>

#define MUTETOGGLE_ACTION_ID "com.lostdomain.zoom.mutetoggle"
#define VIDEOTOGGLE_ACTION_ID "com.lostdomain.zoom.videotoggle"
#define SHARETOGGLE_ACTION_ID "com.lostdomain.zoom.sharetoggle"
#define FOCUS_ACTION_ID "com.lostdomain.zoom.focus"
#define LEAVE_ACTION_ID "com.lostdomain.zoom.leave"
#define RECORDCLOUDTOGGLE_ACTION_ID "com.lostdomain.zoom.recordcloudtoggle"
#define RECORDLOCALTOGGLE_ACTION_ID "com.lostdomain.zoom.recordlocaltoggle"
#define MUTEALL_ACTION_ID "com.lostdomain.zoom.muteall"
#define UNMUTEALL_ACTION_ID "com.lostdomain.zoom.unmuteall"
#define CUSTOMSHORTCUT_ACTION_ID "com.lostdomain.zoom.customshortcut"

std::string m_zoomMenuMeeting = "Meeting";
std::string m_zoomMenuMuteAudio = "Mute Audio";
std::string m_zoomMenuUnmuteAudio = "Unmute Audio";

std::string m_zoomMenuStartVideo = "Start Video";
std::string m_zoomMenuStopVideo = "Stop Video";

std::string m_zoomMenuStartShare = "Start Share";
std::string m_zoomMenuStopShare = "Stop Share";

std::string m_zoomMenuStartRecordToCloud = "Record to the Cloud";
std::string m_zoomMenuStopRecordToCloud = "Stop Recording";
std::string m_zoomMenuStartRecord = "Record";
std::string m_zoomMenuStartRecordLocal = "Record on this Computer";
std::string m_zoomMenuStopRecordLocal = "Stop Recording";

std::string m_zoomMenuWindow = "Window";
std::string m_zoomMenuClose = "Close";
std::string m_zoomMenuZoomMeeting = "Zoom Meeting";

std::string m_zoomMenuMuteAll = "Mute All";
std::string m_zoomMenuUnmuteAll = "Ask All To Unmute";

class CallBackTimer
{
public:
  CallBackTimer() : _execute(false)
  {
  }
  ~CallBackTimer()
  {
    if (_execute.load(std::memory_order_acquire))
    {
      stop();
    };
  }
  void stop()
  {
    _execute.store(false, std::memory_order_release);
    if (_thd.joinable())
      _thd.join();
  }
  void start(int interval, std::function<void(void)> func)
  {
    if (_execute.load(std::memory_order_acquire))
    {
      stop();
    };
    _execute.store(true, std::memory_order_release);
    _thd = std::thread([this, interval, func]() {
      while (_execute.load(std::memory_order_acquire))
      {
        func();
        std::this_thread::sleep_for(std::chrono::milliseconds(interval));
      }
    });
  }
  bool is_running() const noexcept
  {
    return (_execute.load(std::memory_order_acquire) && _thd.joinable());
  }

private:
  std::atomic<bool> _execute;
  std::thread _thd;
};

json getZoomStatus()
{
  // get Zoom Mute status
  std::string status = osGetZoomStatus();
  // ESDDebug("OS script output status - %s", status.c_str());

  if (status.empty()) {
    ESDDebug("getZoomStatus - osGetZoomStatus was empty");
    return json();
  }

  std::string statusMute;
  std::string statusVideo;
  std::string statusShare;
  std::string statusZoom;
  std::string statusRecord;
  std::string statusMuteAll = "enabled";
  std::string statusUnmuteAll = "enabled";

  if (status.find("zoomStatus:open") != std::string::npos)
  {
    //ESDDebug("Zoom Open!");
    statusZoom = "open";
  }
  else if (status.find("zoomStatus:call") != std::string::npos)
  {
    //ESDDebug("Zoom Call!");
    statusZoom = "call";
  }
  else
  {
    //ESDDebug("Zoom Closed!");
    statusZoom = "closed";
  }

  // set mute, video, and sharing to disabled when there's no call
  if (statusZoom != "call")
  {
    //ESDDebug("Zoom closed!");
    statusMute = "disabled";
    statusVideo = "disabled";
    statusShare = "disabled";
    statusRecord = "disabled";
    statusMuteAll = "disabled";
    statusUnmuteAll = "disabled";
  }
  else
  {
    // if there is a call, determine the mute, video, and share status
    if (status.find("zoomMute:muted") != std::string::npos)
    {
      //ESDDebug("Zoom Muted!");
      statusMute = "muted";
    }
    else if (status.find("zoomMute:unmuted") != std::string::npos)
    {
      //ESDDebug("Zoom Unmuted!");
      statusMute = "unmuted";
    }

    if (status.find("zoomVideo:started") != std::string::npos)
    {
      //ESDDebug("Zoom Video Started!");
      statusVideo = "started";
    }
    else if (status.find("zoomVideo:stopped") != std::string::npos)
    {
      //ESDDebug("Zoom Video Stopped!");
      statusVideo = "stopped";
    }

    if (status.find("zoomShare:started") != std::string::npos)
    {
      //ESDDebug("Zoom Screen Sharing Started!");
      statusShare = "started";
    }
    else if (status.find("zoomShare:stopped") != std::string::npos)
    {
      //ESDDebug("Zoom Screen Sharing Stopped!");
      statusShare = "stopped";
    }

    if (status.find("zoomRecord:started") != std::string::npos)
    {
      //ESDDebug("Zoom Record Started!");
      statusRecord = "started";
    }
    else if (status.find("zoomRecord:stopped") != std::string::npos)
    {
      //ESDDebug("Zoom Record Stopped!");
      statusRecord = "stopped";
    }
  }

  //ESDDebug("Zoom status: %s", status.c_str());

  return json({{"statusZoom", statusZoom},
               {"statusMute", statusMute},
               {"statusVideo", statusVideo},
               {"statusRecord", statusRecord},
               {"statusShare", statusShare},
               {"statusMuteAll", statusMuteAll},
               {"statusUnmuteAll", statusUnmuteAll}});
}

ZoomStreamDeckPlugin::ZoomStreamDeckPlugin()
{
  ESDDebug("stored handle");

  // start a timer that updates the current status every 1.5 seconds
  mTimer = new CallBackTimer();
  mTimer->start(1500, [this]() { this->UpdateZoomStatus(); });
}

ZoomStreamDeckPlugin::~ZoomStreamDeckPlugin()
{
  ESDDebug("plugin destructor");
}

void ZoomStreamDeckPlugin::UpdateZoomStatus()
{
  // This is running in a different thread
  if (mConnectionManager != nullptr)
  {
    std::scoped_lock lock(mVisibleContextsMutex);

    //ESDDebug("UpdateZoomStatus");
    // get zoom status for mute, video and whether it's open
    json newStatus = getZoomStatus();
    if (newStatus.empty())
    {
      return;
    }

    //ESDDebug("CURRENT: Zoom status %s", newStatus.dump().c_str());
    // Status images: 0 = active, 1 = cross, 3 = disabled 
    // (the state value '2' for the images is never used but is a placeholder for auto-index advancing done by the Stream Deck system
    //  when you press a button that has multiple states.  the image is the same value as image '1'.  It makes the button UI look correct
    //  by acting like a toggle, but the button is actually a tri-state)
    auto newMuteState = 3;
    auto newVideoState = 3;
    auto newShareState = 3;
    auto newLeaveState = 1;
    auto newRecordState = 3;
    auto newFocusState = 1;
    auto newMuteAllState = 1;
    auto newUnmuteAllState = 1;

    // set mute, video, sharing, and focus to disabled when Zoom is closed
    if (EPLJSONUtils::GetStringByName(newStatus, "statusZoom") == "closed")
    {
      newMuteState = 3;
      newVideoState = 3;
      newShareState = 3;
      newLeaveState = 1;
      newFocusState = 1;
      newRecordState = 3;
      newMuteAllState = 1;
      newUnmuteAllState = 1;
    }
    else if (EPLJSONUtils::GetStringByName(newStatus, "statusZoom") == "open")
    {
      // set mute, video, and sharing to disabled and focus to enabled when there's no call
      newFocusState = 0;
    }
    else
    {
      // if there is a call, determine the mute, video, and share status and enable both focus and leave

      if (EPLJSONUtils::GetStringByName(newStatus, "statusMute") == "muted")
      {
        //ESDDebug("CURRENT: Zoom muted");
        newMuteState = 0;
      }
      else if (EPLJSONUtils::GetStringByName(newStatus, "statusMute") == "unmuted")
      {
        //ESDDebug("CURRENT: Zoom unmuted");
        newMuteState = 1;
      }

      if (EPLJSONUtils::GetStringByName(newStatus, "statusVideo") == "stopped")
      {
        //ESDDebug("CURRENT: Zoom video stopped");
        newVideoState = 0;
      }
      else if (EPLJSONUtils::GetStringByName(newStatus, "statusVideo") == "started")
      {
        //ESDDebug("CURRENT: Zoom video started");
        newVideoState = 1;
      }

      if (EPLJSONUtils::GetStringByName(newStatus, "statusShare") == "stopped")
      {
        newShareState = 0;
      }
      else if (EPLJSONUtils::GetStringByName(newStatus, "statusShare") == "started")
      {
        newShareState = 1;
      }
      if (EPLJSONUtils::GetStringByName(newStatus, "statusRecord") == "stopped")
      {
        //ESDDebug("CURRENT: Zoom record stopped");
        newRecordState = 0;
      }
      else if (EPLJSONUtils::GetStringByName(newStatus, "statusRecord") == "started")
      {
        //ESDDebug("CURRENT: Zoom record started");
        newRecordState = 1;
      }

      // in a call, always have leave, focus, mute all and unmute all enabled
      newLeaveState = 0;
      newFocusState = 0;
      newMuteAllState = 0;
      newUnmuteAllState = 0;
    }

    // sanity check - is the button added?
    if (mButtons.count(MUTETOGGLE_ACTION_ID))
    {
      // update mute button
      const auto button = mButtons[MUTETOGGLE_ACTION_ID];
      // ESDDebug("Mute button context: %s", button.context.c_str());
      mConnectionManager->SetState(newMuteState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(VIDEOTOGGLE_ACTION_ID))
    {
      // update video button
      const auto button = mButtons[VIDEOTOGGLE_ACTION_ID];
      // ESDDebug("Video button context: %s", button.context.c_str());
      mConnectionManager->SetState(newVideoState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(SHARETOGGLE_ACTION_ID))
    {
      // update video button
      const auto button = mButtons[SHARETOGGLE_ACTION_ID];
      // ESDDebug("Video button context: %s", button.context.c_str());
      mConnectionManager->SetState(newShareState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(LEAVE_ACTION_ID))
    {
      // update leave button
      const auto button = mButtons[LEAVE_ACTION_ID];
      // ESDDebug("Leave button context: %s", button.context.c_str());
      mConnectionManager->SetState(newLeaveState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(FOCUS_ACTION_ID))
    {
      // update focus button
      const auto button = mButtons[FOCUS_ACTION_ID];
      // ESDDebug("Focus button context: %s", button.context.c_str());
      mConnectionManager->SetState(newFocusState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(RECORDLOCALTOGGLE_ACTION_ID))
    {
      // update record button
      const auto button = mButtons[RECORDLOCALTOGGLE_ACTION_ID];
      // ESDDebug("Record button context: %s", button.context.c_str());
      mConnectionManager->SetState(newRecordState, button.context);
    }
    // sanity check - is the button added?
    if (mButtons.count(RECORDCLOUDTOGGLE_ACTION_ID))
    {
      // update record button
      const auto button = mButtons[RECORDCLOUDTOGGLE_ACTION_ID];
      // ESDDebug("Record button context: %s", button.context.c_str());
      mConnectionManager->SetState(newRecordState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(MUTEALL_ACTION_ID))
    {
      // update mute all button
      const auto button = mButtons[MUTEALL_ACTION_ID];
      // ESDDebug("Record button context: %s", button.context.c_str());
      mConnectionManager->SetState(newMuteAllState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(UNMUTEALL_ACTION_ID))
    {
      // update unmute all button
      const auto button = mButtons[UNMUTEALL_ACTION_ID];
      // ESDDebug("Record button context: %s", button.context.c_str());
      mConnectionManager->SetState(newUnmuteAllState, button.context);
    }

    // sanity check - is the button added?
    if (mButtons.count(CUSTOMSHORTCUT_ACTION_ID))
    {
      // update unmute all button
      const auto button = mButtons[CUSTOMSHORTCUT_ACTION_ID];
      // ESDDebug("Record button context: %s", button.context.c_str());
      mConnectionManager->SetState(newUnmuteAllState, button.context);
    }
  }
}

void ZoomStreamDeckPlugin::KeyDownForAction(
    const std::string &inAction,
    const std::string &inContext,
    const json &inPayload,
    const std::string &inDeviceID)
{
  const auto state = EPLJSONUtils::GetIntByName(inPayload, "state");
}

void ZoomStreamDeckPlugin::KeyUpForAction(
    const std::string &inAction,
    const std::string &inContext,
    const json &inPayload,
    const std::string &inDeviceID)
{
  ESDDebug("Key Up: %s", inPayload.dump().c_str());
  std::scoped_lock lock(mVisibleContextsMutex);

  json jsonSettings;
  EPLJSONUtils::GetObjectByName(inPayload, "settings", jsonSettings);
  const auto state = EPLJSONUtils::GetIntByName(inPayload, "state");

  if (inAction == MUTETOGGLE_ACTION_ID) {

    // force update the mute toggle button (Stream Deck automatically sets the button to the next state)
    const auto button = mButtons[inAction];
    mConnectionManager->SetState(state == 2 ? 2 : state == 0 ? 1 : 0, button.context);

    std::string zoomMenuMeeting = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMeeting");
    std::string zoomMenuMuteAudio = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMuteAudio");
    std::string zoomMenuUnmuteAudio = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuUnmuteAudio");

    if (!zoomMenuMeeting.empty())
      m_zoomMenuMeeting = zoomMenuMeeting;

    if (!zoomMenuMuteAudio.empty())
      m_zoomMenuMuteAudio = zoomMenuMuteAudio;

    if (!zoomMenuUnmuteAudio.empty())
      m_zoomMenuUnmuteAudio = zoomMenuUnmuteAudio;

    // state == 0 == want to be muted
    if (state == 0) {
      ESDDebug("Unmuting Zoom!");
    } else {
      ESDDebug("Muting Zoom!");
    }

    osToggleZoomMute();
  }
  else if (inAction == SHARETOGGLE_ACTION_ID)
  {
    // force update the mute toggle button (Stream Deck automatically sets the button to the next state)
    const auto button = mButtons[inAction];
    mConnectionManager->SetState(state == 2 ? 2 : state == 0 ? 1 : 0, button.context);

    std::string zoomMenuMeeting = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMeeting");
    std::string zoomMenuStartShare = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStartShare");
    std::string zoomMenuStopShare = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStopShare");

    if (!zoomMenuMeeting.empty())
      m_zoomMenuMeeting = zoomMenuMeeting;

    if (!zoomMenuStartShare.empty())
      m_zoomMenuStartShare = zoomMenuStartShare;

    if (!zoomMenuStopShare.empty())
      m_zoomMenuStopShare = zoomMenuStopShare;

    // state == 0 == want to share
    if (state != 0)
    {
      ESDDebug("Sharing Screen on Zoom!");
    }
    // state == 1 == want to stop sharing
    else
    {
      ESDDebug("Stopping Screen Sharing on Zoom!");
    }

    osToggleZoomShare();
  }
  else if (inAction == VIDEOTOGGLE_ACTION_ID)
  {
    // force update the mute toggle button (Stream Deck automatically sets the button to the next state)
    const auto button = mButtons[inAction];
    mConnectionManager->SetState(state == 2 ? 2 : state == 0 ? 1 : 0, button.context);

    std::string zoomMenuMeeting = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMeeting");
    std::string zoomMenuStartVideo = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStartVideo");
    std::string zoomMenuStopVideo = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStopVideo");

    if (!zoomMenuMeeting.empty())
      m_zoomMenuMeeting = zoomMenuMeeting;

    if (!zoomMenuStartVideo.empty())
      m_zoomMenuStartVideo = zoomMenuStartVideo;

    if (!zoomMenuStopVideo.empty())
      m_zoomMenuStopVideo = zoomMenuStopVideo;

    // state == 0 == want to be with video on
    if (state != 0)
    {
      ESDDebug("Starting Zoom Video!");
    }
    // state == 1 == want to be with video off
    else
    {
      ESDDebug("Stopping Zoom Video!");
    }

    osToggleZoomVideo();
  }
  // focus on Zoom window
  else if (inAction == FOCUS_ACTION_ID)
  {
    ESDDebug("Focusing Zoom window!");
    osFocusZoomWindow();
  }
  // leave Zoom meeting, or end the meeting. When ending, this also clicks "End
  // for all"
  else if (inAction == LEAVE_ACTION_ID)
  {
    std::string zoomMenuWindow = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuWindow");
    std::string zoomMenuClose = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuClose");

    if (!zoomMenuWindow.empty())
      m_zoomMenuWindow = zoomMenuWindow;

    if (!zoomMenuClose.empty())
      m_zoomMenuClose = zoomMenuClose;

    ESDDebug("Leaving Zoom meeting!");
    osLeaveZoomMeeting();
  }

  // toggles cloud recording
  else if (inAction == RECORDCLOUDTOGGLE_ACTION_ID)
  {
    // force update the mute toggle button (Stream Deck automatically sets the button to the next state)
    const auto button = mButtons[inAction];
    mConnectionManager->SetState(state == 2 ? 2 : state == 0 ? 1 : 0, button.context);

    std::string zoomMenuMeeting = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMeeting");
    std::string zoomMenuStartRecordToCloud = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStartRecordToCloud");
    std::string zoomMenuStopRecordToCloud = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStopRecordToCloud");
    std::string zoomMenuStartRecord = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStartRecord");

    if (!zoomMenuMeeting.empty())
      m_zoomMenuMeeting = zoomMenuMeeting;

    if (!zoomMenuStartRecordToCloud.empty())
      m_zoomMenuStartRecordToCloud = zoomMenuStartRecordToCloud;

    if (!zoomMenuStopRecordToCloud.empty())
      m_zoomMenuStopRecordToCloud = zoomMenuStopRecordToCloud;

    if (!zoomMenuStartRecord.empty())
      m_zoomMenuStartRecord = zoomMenuStartRecord;

    ESDDebug("Toggling Recording to the Cloud");
    osToggleZoomRecordCloud();
  }

  // toggles local recording
  else if (inAction == RECORDLOCALTOGGLE_ACTION_ID)
  {
    // force update the mute toggle button (Stream Deck automatically sets the button to the next state)
    const auto button = mButtons[inAction];
    mConnectionManager->SetState(state == 2 ? 2 : state == 0 ? 1 : 0, button.context);

    std::string zoomMenuMeeting = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMeeting");
    std::string zoomMenuStartRecordLocal = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStartRecordLocal");
    std::string zoomMenuStopRecordLocal = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStopRecordLocal");
    std::string zoomMenuStartRecord = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuStartRecord");

    if (!zoomMenuMeeting.empty())
      m_zoomMenuMeeting = zoomMenuMeeting;

    if (!zoomMenuStartRecordLocal.empty())
      m_zoomMenuStartRecordLocal = zoomMenuStartRecordLocal;

    if (!zoomMenuStopRecordLocal.empty())
      m_zoomMenuStopRecordLocal = zoomMenuStopRecordLocal;

    if (!zoomMenuStartRecord.empty())
      m_zoomMenuStartRecord = zoomMenuStartRecord;

    ESDDebug("Toggling Recording Locally");
    osToggleZoomRecordLocal();
  }

  // muting all partitipants in a group meeting
  else if (inAction == MUTEALL_ACTION_ID)
  {
    std::string zoomMenuMeeting = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMeeting");
    std::string zoomMenuMuteAll = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMuteAll");

    if (!zoomMenuMeeting.empty())
      m_zoomMenuMeeting = zoomMenuMeeting;

    if (!zoomMenuMuteAll.empty())
      m_zoomMenuMuteAll = zoomMenuMuteAll;

    ESDDebug("Muting all Participants");
    osMuteAll();
  }

  // toggles local recording
  else if (inAction == UNMUTEALL_ACTION_ID)
  {
    std::string zoomMenuMeeting = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuMeeting");
    std::string zoomMenuUnmuteAll = EPLJSONUtils::GetStringByName(jsonSettings, "zoomMenuUnmuteAll");

    if (!zoomMenuMeeting.empty())
      m_zoomMenuMeeting = zoomMenuMeeting;

    if (!zoomMenuUnmuteAll.empty())
      m_zoomMenuUnmuteAll = zoomMenuUnmuteAll;

    ESDDebug("Asking all Participants to Unmute");
    osUnmuteAll();
  }

  else if(inAction == CUSTOMSHORTCUT_ACTION_ID)
  {
    std::string zoomCustomShortcut = EPLJSONUtils::GetStringByName(jsonSettings, "zoomCustomShortcut");

    // sanity check
    if(!zoomCustomShortcut.empty()) {
      osZoomCustomShortcut(zoomCustomShortcut);
    }
  }
}

void ZoomStreamDeckPlugin::WillAppearForAction(
    const std::string &inAction,
    const std::string &inContext,
    const json &inPayload,
    const std::string &inDeviceID)
{
  std::scoped_lock lock(mVisibleContextsMutex);
  // Remember the button context for the timer updates
  mVisibleContexts.insert(inContext);
  // ESDDebug("Will appear: %s %s", inAction, inContext);
  mButtons[inAction] = {inAction, inContext};
}

void ZoomStreamDeckPlugin::WillDisappearForAction(
    const std::string &inAction,
    const std::string &inContext,
    const json &inPayload,
    const std::string &inDeviceID)
{
  // Remove the context
  std::scoped_lock lock(mVisibleContextsMutex);
  mVisibleContexts.erase(inContext);
  mButtons.erase(inAction);
}

void ZoomStreamDeckPlugin::SendToPlugin(
    const std::string &inAction,
    const std::string &inContext,
    const json &inPayload,
    const std::string &inDeviceID)
{
  // Nothing to do
}

void ZoomStreamDeckPlugin::DeviceDidConnect(
    const std::string &inDeviceID,
    const json &inDeviceInfo)
{
  // Nothing to do
}

void ZoomStreamDeckPlugin::DeviceDidDisconnect(const std::string &inDeviceID)
{
  // Nothing to do
}

void ZoomStreamDeckPlugin::DidReceiveGlobalSettings(const json &inPayload)
{
  ESDDebug("DidReceiveGlobalSettings");
  ESDDebug(EPLJSONUtils::GetString(inPayload).c_str());
}

void ZoomStreamDeckPlugin::DidReceiveSettings(
    const std::string &inAction,
    const std::string &inContext,
    const json &inPayload,
    const std::string &inDeviceID)
{
  ESDDebug("DidReceiveSettings");
  ESDDebug(EPLJSONUtils::GetString(inPayload).c_str());

  WillAppearForAction(inAction, inContext, inPayload, inDeviceID);
}
