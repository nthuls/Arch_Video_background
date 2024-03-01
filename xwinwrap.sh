#!/bin/bash

# Ask the user to select a video file
VIDEO_PATH=$(zenity --file-selection --title="Select a Video" --file-filter="*.mp4 *.mkv *.webm")

# Check if the user cancelled the dialog
if [ -z "$VIDEO_PATH" ]; then
  zenity --error --text="No video selected. Exiting..."
  exit 1
fi

# Directory where IPC sockets will be stored
ipc_dir="/tmp/mpv_sockets"
mkdir -p "$ipc_dir"

# Clean up any existing IPC sockets
rm -f "$ipc_dir"/*

# Function to start playing video on a given monitor with specified geometry
start_video_on_monitor() {
  local monitor_name=$1
  local geometry=$2
  local ipc_socket_path="$ipc_dir/mpvsocket_$monitor_name"


  # Correctly parse the geometry for the scale filter
  local width=$(echo $geometry | cut -d'x' -f1)
  local height=$(echo $geometry | cut -d'x' -f2 | cut -d'+' -f1) # Ensure '+' is not included
 
  echo "Starting video on monitor $monitor_name with geometry $width x $height using IPC socket at $ipc_socket_path"

  # Start xwinwrap with mpv for the monitor
  xwinwrap -ni -ov -g ${width}x${height}+0+0 -- mpv -wid WID --loop=inf --no-audio \
           --input-ipc-server="$ipc_socket_path" \
           --vf=scale=${width}:${height} "$VIDEO_PATH" &
}

# Detect and handle each connected monitor
xrandr | grep ' connected' | while read -r line ; do
  monitor_name=$(echo $line | awk '{print $1}')
  resolution=$(echo $line | grep -oP '(\d+x\d+\+\d+\+\d+)' | head -n 1)
  
  if [ -n "$resolution" ]; then
    # Extract width, height, and position
    # geometry="${resolution}+0+0"
    # Start video on this monitor
    start_video_on_monitor "$monitor_name" "$resolution"
  else
    echo "No valid resolution found for monitor $monitor_name, skipping..."
  fi
done

# Function to send a command to all mpv instances
send_command_to_all_mpv_instances() {
  local command=$1
  for ipc_socket_path in "$ipc_dir"/*; do
    if [ -e "$ipc_socket_path" ]; then
      echo $command | socat - "UNIX-CONNECT:$ipc_socket_path"
    else
      echo "IPC socket $ipc_socket_path not found, skipping..."
    fi
  done
}

# Function to pause video on all monitors
pause_video() {
  send_command_to_all_mpv_instances '{ "command": ["set_property", "pause", true] }'
}

# Function to resume video on all monitors
resume_video() {
  send_command_to_all_mpv_instances '{ "command": ["set_property", "pause", false] }'
}

# Continuously check the focused window and pause/resume the video accordingly
while true; do
  # Get the ID of the currently active window
  active_window_id=$(xdotool getactivewindow)
  
  # Get the name of the active window (or use getwindowclassname for class)
  active_window_name=$(xdotool getwindowname "$active_window_id")
  
  # Placeholder: Check if the active window is your desktop or a specific application
  # This condition is very much dependent on your desktop environment and the applications you use
  # For example, you might check if the active window name contains "Desktop" or is a specific app name
  if [[ "$active_window_name" == *"Desktop"* ]]; then
    resume_video
  else
    pause_video
  fi
  
  sleep 1 # Check every second (adjust as needed)
done
