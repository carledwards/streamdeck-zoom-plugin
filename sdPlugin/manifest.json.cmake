{
  "Actions": [
    {
      "States": [
        {
          "Image": "streamdeck-zoom-muted"
        },
        {
          "Image": "streamdeck-zoom-unmuted"
        },
        {
          "Image": "streamdeck-zoom-muted"
        },
        {
          "Image": "streamdeck-zoom-muted-closed"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-muted-actionicon",
      "Name": "Mute Toggle",
      "Tooltip": "Toggle Zoom Mute Status",
      "UUID": "com.lostdomain.zoom.mutetoggle",
      "PropertyInspectorPath": "propertyinspector/index-mute.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-video-stopped"
        },
        {
          "Image": "streamdeck-zoom-video-started"
        },
        {
          "Image": "streamdeck-zoom-video-stopped"
        },
        {
          "Image": "streamdeck-zoom-video-closed"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-video-actionicon",
      "Name": "Video Toggle",
      "Tooltip": "Toggle Zoom Video",
      "UUID": "com.lostdomain.zoom.videotoggle",
      "PropertyInspectorPath": "propertyinspector/index-video.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-share-start"
        },
        {
          "Image": "streamdeck-zoom-share-stop"
        },
        {
          "Image": "streamdeck-zoom-share-start-placeholder"
        },
        {
          "Image": "streamdeck-zoom-share-closed"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-share-actionicon",
      "Name": "Share Toggle",
      "Tooltip": "Bring up the share screen window, or stop sharing",
      "UUID": "com.lostdomain.zoom.sharetoggle",
      "PropertyInspectorPath": "propertyinspector/index-share.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-focus"
        },
        {
          "Image": "streamdeck-zoom-focus-closed"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-focus-actionicon",
      "Name": "Focus",
      "Tooltip": "Bring the Zoom window to the front",
      "UUID": "com.lostdomain.zoom.focus",
      "PropertyInspectorPath": "propertyinspector/index.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-leave"
        },
        {
          "Image": "streamdeck-zoom-leave-closed"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-leave-actionicon",
      "Name": "Leave Meeting",
      "Tooltip": "Leave an active meeting. If you're the host, this ends the meeting.",
      "UUID": "com.lostdomain.zoom.leave",
      "PropertyInspectorPath": "propertyinspector/index-leave.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-record-cloud-stopped"
        },
        {
          "Image": "streamdeck-zoom-record-cloud-started"
        },
        {
          "Image": "streamdeck-zoom-record-cloud-stopped-placeholder"
        },
        {
          "Image": "streamdeck-zoom-record-cloud-disabled"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-record-cloud-actionicon",
      "Name": "Cloud Record Toggle",
      "Tooltip": "Toggle Zoom Recording to the Cloud",
      "UUID": "com.lostdomain.zoom.recordcloudtoggle",
      "PropertyInspectorPath": "propertyinspector/index-record-cloud.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-record-local-stopped"
        },
        {
          "Image": "streamdeck-zoom-record-local-started"
        },
        {
          "Image": "streamdeck-zoom-record-local-stopped-placeholder"
        },
        {
          "Image": "streamdeck-zoom-record-local-disabled"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-record-local-actionicon",
      "Name": "Local Record Toggle",
      "Tooltip": "Toggle Zoom Recording to your local computer",
      "UUID": "com.lostdomain.zoom.recordlocaltoggle",
      "PropertyInspectorPath": "propertyinspector/index-record-local.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-unmuteall"
        },
        {
          "Image": "streamdeck-zoom-unmuteall-disabled"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-unmuteall-actionicon",
      "Name": "Ask All to Unmute",
      "Tooltip": "Ask all participants to unmute",
      "UUID": "com.lostdomain.zoom.unmuteall",
      "PropertyInspectorPath": "propertyinspector/index-unmute-all.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-muteall"
        },
        {
          "Image": "streamdeck-zoom-muteall-disabled"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-muteall-actionicon",
      "Name": "Mute All Participants",
      "Tooltip": "Mute All Participants",
      "UUID": "com.lostdomain.zoom.muteall",
      "PropertyInspectorPath": "propertyinspector/index-mute-all.html"
    },
    {
      "States": [
        {
          "Image": "streamdeck-zoom-customshortcut"
        },
        {
          "Image": "streamdeck-zoom-customshortcut-disabled"
        }
      ],
      "SupportedInMultiActions": true,
      "Icon": "streamdeck-zoom-customshortcut-actionicon",
      "Name": "Custom Shortcut",
      "Tooltip": "Add a custom shortcut to do anything that Zoom supports",
      "UUID": "com.lostdomain.zoom.customshortcut",
      "PropertyInspectorPath": "propertyinspector/index-customshortcut.html"
    }
  ],
  "CodePath": "sdzoomplugin.exe",
  "CodePathMac": "sdzoomplugin",
  "Author": "Martijn Smit",
  "Description": "Control your Zoom meetings; easily mute yourself, start your video, share, record, quickly leave the meeting, and more.",
  "URL": "https://lostdomain.org/stream-deck-plugin-for-zoom/",
  "Name": "Zoom Plugin",
  "Category": "Zoom",
  "CategoryIcon": "video-camera",
  "Icon": "video-camera-plugin",
  "Version": "${CMAKE_PROJECT_VERSION}",
  "OS": [
    {
      "Platform": "mac",
      "MinimumVersion": "10.13"
    },
    {
      "Platform": "windows",
      "MinimumVersion" : "10"
    }
  ],
  "SDKVersion": 2,
  "Software": {
    "MinimumVersion": "4.1"
  }
}
