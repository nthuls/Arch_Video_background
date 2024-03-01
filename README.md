'''
BOTH WORK
sudo systemctl start xwinwrap.service
OR
xwinwrap.sh
'''

# Arch_Video_background

Make sure to adjust the path to your video file as needed and verify that all dependencies (xwinwrap, mpv, socat, xdotool, zenity) are correctly installed on your system. Also, ensure that the IPC socket directory (/tmp/mpv_sockets) has the correct permissions for your script to create and write to it.


Run as executable chmod +x xwinwrap.sh
Then ./xwinwrap.sh


To run without output use:
nohup ./xwinwrap.sh &

Running in Background: 
  After integrating these changes, use nohup ./xwinwrap.sh & to run your script in the background.

Stopping the Script: 

  Since the script is running in the background, you might want to manage its execution (e.g., stopping it) more     conveniently. Consider saving the background job's PID to a file ```(echo $! > script.pid)``` right after starting it. You   can then stop the script using kill $(cat script.pid).

ADJUSTING PERMISSIONS OF THE FOLDER 

Yes, you can grant your user permissions to execute scripts or access files in a specific directory like `/usr/local/bin/`. This directory is typically used for system-wide installation of custom scripts and executables that are not managed by the system's package manager. By default, `/usr/local/bin/` is usually writable by the root user and readable/executable by all users. If you want to ensure your user has the necessary permissions to execute scripts and possibly write or modify them in `/usr/local/bin/`, you can adjust the permissions or ownership of the files within.

### Changing File Ownership

If you want your user to own the script, you can change the ownership with `chown`. Replace `nthuli` with your username and `xwinwrap.sh` with the name of your script:

```bash
sudo chown USER:USER /usr/local/bin/xwinwrap.sh
```

This command makes `USER` the owner of `xwinwrap.sh`, allowing full access to the file based on its permissions.

### Adjusting File Permissions

To ensure your user can execute the script, you need to make sure the execute bit is set. To add execute permissions for the file owner, you can use `chmod`:

```bash
chmod u+x /usr/local/bin/xwinwrap.sh
```

If you want to make the script executable by any user, you can set the execute bit for all users:

```bash
sudo chmod +x /usr/local/bin/xwinwrap.sh
```

### Granting Write Access

If you want your user to be able to modify scripts in `/usr/local/bin/` without giving them ownership, you can add your user to a specific group (e.g., `staff`), change the group ownership of the directory or file to that group, and then set the appropriate group permissions.

1. **Add your user to a group** (creating a new group if necessary). Here we'll use `staff` as an example:

```bash
sudo usermod -a -G staff nthuli
```

2. **Change the group ownership of the script** or the `/usr/local/bin/` directory:

```bash
sudo chown :staff /usr/local/bin/xwinwrap.sh
# Or for the entire directory
sudo chown :staff /usr/local/bin/
```

3. **Set the desired group permissions** (write and execute for this example):

```bash
sudo chmod g+wx /usr/local/bin/xwinwrap.sh
# Or for the entire directory
sudo chmod g+wx /usr/local/bin/
```

After this, log out and back in for the group changes to take effect.

### Note 

TO CHANGE PERMISSION CHECK THE FILE:(https://github.com/nthuls/Arch_Video_background/blob/main/View%20Groups%20and%20more)

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
After=graphical.target

[Service]
Type=forking
User=<username>
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/<username>/.Xauthority"
ExecStart=/usr/local/bin/xwinwrap.sh
Restart=on-failure
RestartSec=10s
TimeoutStartSec=infinity

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
To start the service without blocking your terminal, you can use the & symbol to put the command in the background, or better yet, use the systemctl start command with the --no-block option. This option tells systemctl to return immediately without waiting for the service to start:

```bash
sudo systemctl start xwinwrap.service --no-block
```
This way, you can continue using your terminal without waiting for the service to fully start.
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
