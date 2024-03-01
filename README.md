# Arch_Video_background

Make sure to adjust the path to your video file as needed and verify that all dependencies (xwinwrap, mpv, socat, xdotool, zenity) are correctly installed on your system. Also, ensure that the IPC socket directory (/tmp/mpv_sockets) has the correct permissions for your script to create and write to it.


Run as executable chmod +x xwinwrap.sh
Then ./xwinwrap.sh


To run without output use:
nohup ./xwinwrap.sh &

Running in Background: 
  After integrating these changes, use nohup ./xwinwrap.sh & to run your script in the background.

Stopping the Script: 

  Since the script is running in the background, you might want to manage its execution (e.g., stopping it) more     conveniently. Consider saving the background job's PID to a file '(echo $! > script.pid)' right after starting it. You   can then stop the script using kill $(cat script.pid).
