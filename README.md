# Arch_Video_background

Make sure to adjust the path to your video file as needed and verify that all dependencies (xwinwrap, mpv, socat, xdotool, zenity) are correctly installed on your system. Also, ensure that the IPC socket directory (/tmp/mpv_sockets) has the correct permissions for your script to create and write to it.


Run as executable chmod +x xwinwrap.sh
Then ./xwinwrap.sh


To run without output use:
nohup ./xwinwrap.sh &

Running in Background: 
  After integrating these changes, use nohup ./xwinwrap.sh & to run your script in the background.

Stopping the Script: 

  Since the script is running in the background, you might want to manage its execution (e.g., stopping it) more     conveniently. Consider saving the background job's PID to a file (echo $! > script.pid) right after starting it. You   can then stop the script using kill $(cat script.pid).

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

### Note on Security

While it's generally safe to adjust permissions for individual scripts, broadening write access to `/usr/local/bin/` can have security implications. It's recommended to limit write access to system directories only to users who need to manage system-wide scripts and executables, and always be cautious about executing scripts with elevated privileges.
