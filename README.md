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


TO MAKE IT AN EXECUTABLE WHICH IS MUCH EASIER

Creating a systemd service is a robust way to manage your script as a background service, allowing you to start, stop, and enable it to run at boot with ease. Here's how you can create a systemd service for your script:

### Step 1: Create the Script

Ensure your script is finalized and located in a suitable directory. For example, let's assume your script is saved as `/usr/local/bin/xwinwrap.sh` and is executable (`chmod +x /usr/local/bin/xwinwrap.sh`).

### Step 2: Create a Systemd Service File

1. **Open a new service file in a text editor** with root privileges. For example, using `nano`:

```bash
sudo nano /etc/systemd/system/xwinwrap.service
```

2. **Add the following content** to the service file. Adjust the `ExecStart` path if your script is located elsewhere or needs specific environment variables or paths.

```ini
[Unit]
Description=Xwinwrap Background Video Service
After=display-manager.service

[Service]
Type=simple
User=<your usersname>
ExecStart=/usr/local/bin/xwinwrap.sh
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=graphical.target
```

Replace `User=<your usersname>` with your actual username on the system.

3. **Save and exit** the text editor. If you're using `nano`, that would be Ctrl+O, Enter, and then Ctrl+X.

### Step 3: Enable and Start the Service

- **Reload systemd** to recognize your new service:

```bash
sudo systemctl daemon-reload
```

- **Enable the service** to start at boot:

```bash
sudo systemctl enable xwinwrap.service
```

- **Start the service** now without rebooting:

```bash
sudo systemctl start xwinwrap.service
```

### Step 4: Managing the Service

- **To stop the service**, use:

```bash
sudo systemctl stop xwinwrap.service
```

- **To check the status** of the service, use:

```bash
sudo systemctl status xwinwrap.service
```

### Notes

- **Script Adjustments**: Since the script will now run as a service, including user interaction (like Zenity dialogs) directly in the script won't work. You'll need to set the video path within the script or use a configuration file/environment variable that the script reads from, which you can modify as needed.
- **Environment Variables**: If your script depends on environment variables that are set in your user session, you may need to define them in the service file or ensure the script is executed in an environment where those variables are set.
- **User Session**: Since the service starts with the system, it needs to know which X session to attach to if it's doing anything GUI-related. This is why it starts `After=display-manager.service`. However, depending on your setup, you might need to adjust this or deal with X authorization differently.

Creating a systemd service like this provides you with robust control over your script, making it easy to ensure it's always running when you need it and is properly managed by the system.
