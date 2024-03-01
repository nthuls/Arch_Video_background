#!/bin/bash

# Global variable for the background process IDs
declare -a xwinwrap_pids

# Path to store the last video path
last_video_path_file="/tmp/last_video_path.txt"

# Function to clean up and exit
cleanup_and_exit() {
  echo "Cleaning up and exiting..."
  # Send a command to all mpv instances to quit
  send_command_to_all_mpv_instances '{ "command": ["quit"] }'
  
  # Kill all xwinwrap processes
  for pid in "${xwinwrap_pids[@]}"; do
    kill "$pid" 2>/dev/null
  done

  # Clean up any other resources or temporary files
  rm -f "$ipc_dir"/*
  
  # Ask user before removing last video path file
  if [ -f "$last_video_path_file" ]; then
    if zenity --question --title="Cleanup" --text="Do you want to remove the last video path file?" --ok-label="Yes" --cancel-label="No"; then
      rm -f "$last_video_path_file"
    fi
  fi

  exit 0
}


# Function to stop all running instances of this script, xwinwrap, and mpv
stop_script() {
  # Find PIDs of the running script instances, excluding the current instance and the grep process itself
  script_pids=$(pgrep -f "$(basename "$0")" | grep -v $$ | grep -v grep)
  for pid in $script_pids; do
    kill -SIGTERM "$pid"
  done

  # Additionally send SIGTERM to xwinwrap and mpv processes directly if needed
  pkill -f xwinwrap
  pkill -f mpv
  exit 0
}

# Check for command line argument "stop"
if [ "$1" == "stop" ]; then
  stop_script
fi

# Trap SIGINT and SIGTERM signals to run the cleanup_and_exit function
trap cleanup_and_exit SIGINT SIGTERM

# Check if the last video path file exists and read it
if [ -f "$last_video_path_file" ]; then
  last_video_path=$(cat "$last_video_path_file")
  if zenity --question --title="Select Video" --text="Do you want to use the last video?\nLast video: $last_video_path" --ok-label="Yes" --cancel-label="No"; then
    VIDEO_PATH="$last_video_path"
  else
    VIDEO_PATH=$(zenity --file-selection --title="Select a Video" --file-filter="*.mp4 *.mkv *.webm")
    if [ -z "$VIDEO_PATH" ]; then
      zenity --error --text="No video selected. Exiting..."
      exit 1
    fi
    echo "$VIDEO_PATH" > "$last_video_path_file"
  fi
else
  VIDEO_PATH=$(zenity --file-selection --title="Select a Video" --file-filter="*.mp4 *.mkv *.webm")
  if [ -z "$VIDEO_PATH" ]; then
    zenity --error --text="No video selected. Exiting..."
    exit 1
  fi
  echo "$VIDEO_PATH" > "$last_video_path_file"
fi

# Ask user if they want the video to auto-pause
auto_pause=0
if zenity --question --title="Video Playback" --text="Do you want the video to pause automatically when not on the desktop?" --ok-label="Yes" --cancel-label="No"; then
  auto_pause=1
fi

# Directory where IPC sockets will be stored
ipc_dir="/tmp/mpv_sockets"
mkdir -p "$ipc_dir"
rm -f "$ipc_dir"/* # Clean up any existing IPC sockets

# Function to start playing video on a given monitor with specified geometry
start_video_on_monitor() {
  local monitor_name=$1
  local geometry=$2
  local ipc_socket_path="$ipc_dir/mpvsocket_$monitor_name"

  local width=$(echo $geometry | cut -d'x' -f1)
  local height=$(echo $geometry | cut -d'x' -f2 | cut -d'+' -f1)

  xwinwrap -ni -ov -g ${width}x${height}+0+0 -- mpv -wid WID --loop=inf --no-audio \
           --input-ipc-server="$ipc_socket_path" \
           --vf=scale=${width}:${height} "$VIDEO_PATH" &

  xwinwrap_pids+=("$!")
}

# Function to send a command to all mpv instances
send_command_to_all_mpv_instances() {
  local command=$1
  for ipc_socket_path in "$ipc_dir"/*; do
    if [ -e "$ipc_socket_path" ]; then
      echo $command | socat - "UNIX-CONNECT:$ipc_socket_path"
    fi
  done
}

# Detect and handle each connected monitor
xrandr | grep ' connected' | while read -r line ; do
  monitor_name=$(echo $line | awk '{print $1}')
  resolution=$(echo $line | grep -oP '(\d+x\d+\+\d+\+\d+)' | head -n 1)

  if [ -n "$resolution" ]; then
    start_video_on_monitor "$monitor_name" "$resolution"
  else
    echo "No valid resolution found for monitor $monitor_name, skipping..."
  fi
done

# Function to pause video playback on all monitors
pause_video() {
  send_command_to_all_mpv_instances '{ "command": ["set_property", "pause", true] }'
}

# Function to resume video playback on all monitors
resume_video() {
  send_command_to_all_mpv_instances '{ "command": ["set_property", "pause", false] }'
}

# Start video playback based on the auto_pause setting
if [ "$auto_pause" -eq 0 ]; then
  echo "Auto-pause is disabled. Videos will play continuously."

  # Function to start playing video on all monitors without auto-pause
  start_video_without_auto_pause() {
    # Detect and handle each connected monitor
    xrandr | grep ' connected' | while read -r line ; do
      monitor_name=$(echo $line | awk '{print $1}')
      resolution=$(echo $line | grep -oP '(\d+x\d+\+\d+\+\d+)' | head -n 1)

      if [ -n "$resolution" ]; then
        local ipc_socket_path="$ipc_dir/mpvsocket_$monitor_name"
        local width=$(echo $resolution | cut -d'x' -f1)
        local height=$(echo $resolution | cut -d'x' -f2 | cut -d'+' -f1)

        xwinwrap -ni -ov -g ${width}x${height}+0+0 -- mpv -wid WID --loop=inf --no-audio \
                 --input-ipc-server="$ipc_socket_path" \
                 --vf=scale=${width}:${height} "$VIDEO_PATH" &

        xwinwrap_pids+=("$!")
      else
        echo "No valid resolution found for monitor $monitor_name, skipping..."
      fi
    done
  }

  # Start the video playback without auto-pause
  start_video_without_auto_pause
else
  # Handle auto-pause enabled scenario separately
  echo "Auto-pause is enabled. Videos will pause when not viewing the desktop."
  # The existing logic to handle auto-pause goes here
fi

#Continuously check the focused window and pause/resume the video accordingly, if auto-pause is enabled
if [ "$auto_pause" -eq 1 ]; then
  while true; do
    active_window_id=$(xdotool getactivewindow)
    active_window_name=$(xdotool getwindowname "$active_window_id")

    if [[ "$active_window_name" == *"Desktop"* ]]; then
      resume_video
    else
      pause_video
    fi

    sleep 1 # Check every second


  done
else
  echo "Auto-pause is disabled. Videos will play continuously."
  start_video_without_auto_pause
fi
