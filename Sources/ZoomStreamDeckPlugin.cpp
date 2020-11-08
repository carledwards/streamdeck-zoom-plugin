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
  //ESDDebug("OS script output status - %s", zoomStatus);

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

  //ESDDebug("Zoom status: %s", status);

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

  // start a timer that updates the current status every 3 seconds
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
    //ESDDebug("CURRENT: Zoom status %s", newStatus.dump().c_str());
    // Status images: 0 = active, 1 = cross, 2 = disabled
    auto newMuteState = 2;
    auto newVideoState = 2;
    auto newShareState = 2;
    auto newLeaveState = 1;
    auto newRecordState = 2;
    auto newFocusState = 1;
    auto newMuteAllState = 1;
    auto newUnmuteAllState = 1;

    // set mute, video, sharing, and focus to disabled when Zoom is closed
    if (EPLJSONUtils::GetStringByName(newStatus, "statusZoom") == "closed")
    {
      newMuteState = 2;
      newVideoState = 2;
      newShareState = 2;
      newLeaveState = 1;
      newFocusState = 1;
      newRecordState = 2;
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

  const auto state = EPLJSONUtils::GetIntByName(inPayload, "state");
  bool updateStatus = false;
  auto newState = 0;

  if (inAction == MUTETOGGLE_ACTION_ID)
  {
    // state == 0 == want to be muted
    if (state != 0)
    {
      ESDDebug("Unmuting Zoom!");
    }
    // state == 1 == want to be unmuted
    else
    {
      ESDDebug("Muting Zoom!");
    }

    osToggleZoomMute();
    updateStatus = true;
  }
  else if (inAction == SHARETOGGLE_ACTION_ID)
  {
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
    updateStatus = true;
  }
  else if (inAction == VIDEOTOGGLE_ACTION_ID)
  {
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
    updateStatus = true;
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
    ESDDebug("Leaving Zoom meeting!");
    osLeaveZoomMeeting();
  }

  // toggles cloud recording
  else if (inAction == RECORDCLOUDTOGGLE_ACTION_ID)
  {
    ESDDebug("Toggling Recording to the Cloud");
    osToggleZoomRecordCloud();
  }

  // toggles local recording
  else if (inAction == RECORDLOCALTOGGLE_ACTION_ID)
  {
    ESDDebug("Toggling Recording Locally");
    osToggleZoomRecordLocal();
  }

  // muting all partitipants in a group meeting
  else if (inAction == MUTEALL_ACTION_ID)
  {
    ESDDebug("Muting all Participants");
    osMuteAll();
  }

  // toggles local recording
  else if (inAction == UNMUTEALL_ACTION_ID)
  {
    ESDDebug("Asking all Participants to Unmute");
    osUnmuteAll();
  }

  if (updateStatus)
  {
    UpdateZoomStatus();
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
  json outPayload;

  const auto event = EPLJSONUtils::GetStringByName(inPayload, "event");
  ESDDebug("Received event %s", event.c_str());

  if (event == "getDeviceList")
  {
    mConnectionManager->SendToPropertyInspector(
        inAction, inContext,
        json(
            {{"event", event}, {"zoomStatus", "open"}, {"muteStatus", "muted"}}));
    return;
  }
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
}

void ZoomStreamDeckPlugin::DidReceiveSettings(
    const std::string &inAction,
    const std::string &inContext,
    const json &inPayload,
    const std::string &inDeviceID)
{
  WillAppearForAction(inAction, inContext, inPayload, inDeviceID);
}
